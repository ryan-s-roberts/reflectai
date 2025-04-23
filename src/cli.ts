#!/usr/bin/env node
import { Command } from 'commander';
import { b } from './baml_client/index';
import type { Dialogue, DialogueTurn, ModalityEvent, TurnSpecificVisualEvents, SessionAnalysis, SessionTheme, KeyMoment, TherapeuticObservation, EvidenceReference, EvidencePointer, TimelineData, TimelineSection, TimelineEvent, SpeakerType } from './baml_client/types';
import { EventSourceType } from './baml_client/types';
import { BamlErrors } from '@boundaryml/baml';
import * as fs from 'fs';
import * as path from 'path';
import _ from 'lodash';

// ----- Intermediate Report Model Interfaces -----

// Interface for linking analysis items back to dialogue turns OR specific events
interface ReportEvidenceLink {
  text: string; // e.g., "Turn 3" or "Turn 3, Event 1"
  targetId: string; // e.g., "#turn-3" or "#turn-3-event-1"
}

// Interface for reporting on a single dialogue turn
interface ReportDialogueTurn {
  id: string; // Anchor ID for the turn header, e.g., "turn-1-patient"
  speaker: string;
  utterance: string;
  // Revert: Store events as simple text strings now 
  // events: { id: string; text: string }[]; // REVERTED
  events: string[]; // Keep as simple string array
}

// Interface for reporting on a session theme
interface ReportTheme {
  theme: string;
  evidenceSummary?: string | null; // BAML type uses '?' which means string | null | undefined
  evidenceLinks: ReportEvidenceLink[];
}

// Interface for reporting on a key moment
interface ReportKeyMoment {
  turnIndex: number;
  description: string;
  dialogueSnippet?: string | null;
  relevantEvents: string[]; // Pre-formatted modality event strings
  imageCorrelationNotes?: string | null;
  turnLink: ReportEvidenceLink;
}

// Interface for reporting on a therapeutic observation
interface ReportTherapeuticObservation {
  turnIndex: number;
  observation: string;
  evidenceSummary?: string | null;
  evidenceLinks?: ReportEvidenceLink[]; // Pointer links
  turnLink: ReportEvidenceLink;
}

// Top-level interface for the entire report structure
interface ReportModel {
  title: string;
  backgroundContext: string;
  dialogue: ReportDialogueTurn[];
  timelineData: TimelineData; // Changed from mermaidTimeline: string
  analysis: {
    overallSummary: string;
    identifiedThemes: ReportTheme[];
    keyMoments: ReportKeyMoment[];
    therapeuticObservations: ReportTherapeuticObservation[];
  };
}

// ----- End Intermediate Report Model Interfaces -----

const program = new Command();

program
  .name('reflectai-cli')
  .description('CLI tool for interacting with BAML therapy session synthesis and analysis using ReflectAI')
  .version('1.0.0')
  .option('-o, --output <filepath>', 'Optional path to save analysis as Markdown report');

program.command('synthesize')
  .description('Synthesize and analyze a therapy session')
  .requiredOption('-c, --background-context <text>', 'Background context for the session')
  .requiredOption('-l, --session-length <minutes>', 'Approximate session length in minutes', (value) => {
    const parsedValue = parseInt(value, 10);
    if (isNaN(parsedValue) || parsedValue <= 0) {
      throw new Error('session-length must be a positive number.');
    }
    return parsedValue;
  })
  .action(async (options: { backgroundContext: string; sessionLength: number }) => {
    const globalOptions = program.opts<{ output?: string }>();
    console.log('Starting session synthesis...');
    try {
      // 1. Synthesize base dialogue
      const dialogue: Dialogue = await b.SynthesizeTherapySession(
        options.backgroundContext,
        options.sessionLength
      );
      console.log(`Synthesized initial dialogue with ${dialogue.turns.length} turns.`);

      // 2. Synthesize visual observations (now expects TurnSpecificVisualEvents[])
      const visualEventsList: TurnSpecificVisualEvents[] = await b.SynthesizeVisualEvents(
        options.backgroundContext,
        dialogue
      );
      console.log(`Synthesized visual events for ${visualEventsList.length} patient turns.`);

      // 3. Merge visual observations into the dialogue
      const mergedDialogue: Dialogue = mergeVisualEvents(dialogue, visualEventsList);
      console.log('Merged visual events into dialogue.');

      // 4. Analyze the merged dialogue
      console.log('Starting multimodal analysis...');
      const analysisResult: SessionAnalysis = await b.AnalyzeSessionMultimodal(
        mergedDialogue,
        options.backgroundContext
      );
      console.log('Analysis complete.');

      // 5. Generate Structured Timeline Data (FIXED CALL + Updated Function Name)
      console.log('Generating structured timeline data...');
      const timelineDataResult: TimelineData = await b.GenerateTimelineData(
        mergedDialogue,  // Positional argument 1
        analysisResult   // Positional argument 2
      );
      console.log('Timeline data generated.');

      // 6. Output result (JSON or Markdown)
      if (globalOptions.output) {
        console.log(`Generating Markdown report at: ${globalOptions.output}`);
        // Pass the structured timeline data to the report generator
        const markdownContent = generateMarkdownReport(
          options.backgroundContext,
          mergedDialogue,
          analysisResult,
          timelineDataResult // Pass the structured data object
        );
        const outputDir = path.dirname(globalOptions.output);
        if (!fs.existsSync(outputDir)){
            fs.mkdirSync(outputDir, { recursive: true });
        }
        fs.writeFileSync(globalOptions.output, markdownContent);
        console.log('Markdown report saved successfully.');
      } else {
        console.log('\n--- Session Analysis Result (JSON) ---');
        console.log(JSON.stringify(analysisResult, null, 2));
        console.log('\n--- Timeline Data (JSON) ---');
        console.log(JSON.stringify(timelineDataResult, null, 2));
      }

    } catch (error: unknown) {
      console.error('\nError during processing:');
      // Simplified error handling for now
      if (error instanceof Error) {
        console.error(`Error: ${error.message}`);
        console.error(error.stack);
      } else {
        console.error('An unknown error occurred:', error);
      }
      process.exit(1);
    }
  });

/**
 * Merges synthesized visual events into the corresponding PATIENT turns
 * of a dialogue object.
 */
function mergeVisualEvents(
  dialogue: Dialogue,
  visualEventsList: TurnSpecificVisualEvents[] // Updated type
): Dialogue {
  // Create a deep copy to avoid modifying the original dialogue object
  const updatedDialogue: Dialogue = JSON.parse(JSON.stringify(dialogue));

  // Create a map for quick lookup of visual events by turn index.
  const visualEventsMap = new Map<number, ModalityEvent[]>();
  visualEventsList.forEach(item => {
    // Assuming item.visual_events contains the ModalityEvent[] directly
    visualEventsMap.set(item.turn_index, item.visual_events);
  });

  updatedDialogue.turns.forEach((turn: DialogueTurn, index: number) => {
    // Only add visual events to PATIENT turns
    if (turn.speaker === 'PATIENT') {
      const visualEvents = visualEventsMap.get(index); // Lookup by the turn's actual index

      if (visualEvents && visualEvents.length > 0) {
        // Ensure the events array exists
        if (!turn.events) {
          turn.events = [];
        }
        // Add the visual events (already ModalityEvent objects)
        // Filter to ensure we only add VISUAL_ANALYSIS source, just in case
        turn.events.push(...visualEvents.filter(e => e.source === EventSourceType.VISUAL_ANALYSIS));
      }
    }
  });

  return updatedDialogue;
}

// ----- Markdown Report Generation Functions -----

// Helper to format a single modality event
function formatModalityEvent(event: ModalityEvent): string {
  // Use lodash startCase for readability
  const readableSource = _.startCase(event.source.toLowerCase());
  let formatted = `\`${readableSource}\`: ${event.description}`;
  if (event.confidence !== undefined && event.confidence !== null) {
    formatted += ` (Confidence: ${event.confidence.toFixed(2)})`;
  }
  return formatted;
}

// Helper generates link text and target ID based on turn index + speaker
function createTurnLink(turnIndex: number, speaker: string): ReportEvidenceLink {
    const cleanSpeaker = speaker.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const targetId = `#turn-${turnIndex + 1}-${cleanSpeaker}`; // e.g., #turn-1-patient
    return {
        text: `Turn ${turnIndex + 1} (${speaker})`, 
        targetId: targetId
    };
}

// Helper to format evidence pointers, linking only to the turn header
function formatEvidenceLinks(pointers?: EvidencePointer[] | null): ReportEvidenceLink[] {
    if (!pointers || pointers.length === 0) {
        return [];
    }
    // Need the dialogue context to get the speaker for the target ID
    // This is a limitation; we'll simplify for now and just link to Turn #
    // A better approach might involve passing dialogue context here or restructuring.
    // For now, just create simple turn links based on unique indices.
    const uniqueLinks = new Map<number, ReportEvidenceLink>();
    pointers.forEach(p => {
        if (!uniqueLinks.has(p.turn_index)) {
             // Link text can still mention the event for context, but target is the turn
            const linkText = `Turn ${p.turn_index + 1} (Event ${p.event_index + 1})`; 
            uniqueLinks.set(p.turn_index, { text: linkText, targetId: `#turn-${p.turn_index + 1}` }); // Simplistic target
        }
    });
    return Array.from(uniqueLinks.values()).sort((a,b) => parseInt(a.text.split(' ')[1]) - parseInt(b.text.split(' ')[1]));
}

// Maps BAML output to the intermediate ReportModel
function mapBamlToReportModel(
  backgroundContext: string,
  mergedDialogue: Dialogue,
  analysisResult: SessionAnalysis,
  timelineData: TimelineData // Accept TimelineData object
): ReportModel {

  // Map dialogue turns
  const reportDialogue: ReportDialogueTurn[] = mergedDialogue.turns.map((turn, turnIndex) => {
    const turnLink = createTurnLink(turnIndex, turn.speaker);
    return {
      id: turnLink.targetId.substring(1),
      speaker: turn.speaker,
      utterance: turn.utterance || '_No utterance provided_',
      events: (turn.events || []).map(formatModalityEvent),
    };
  });

  // Map analysis sections
  const reportAnalysis = {
    overallSummary: analysisResult.overall_summary,
    identifiedThemes: analysisResult.identified_themes.map((theme: SessionTheme) => {
      return {
        theme: theme.theme,
        evidenceSummary: theme.evidence_summary,
        evidenceLinks: theme.evidence_turn_indices.sort((a, b) => a - b).map(idx => {
          const speaker = mergedDialogue.turns[idx]?.speaker || 'UNKNOWN';
          return createTurnLink(idx, speaker);
        }),
      };
    }),
    keyMoments: analysisResult.key_moments.map((moment: KeyMoment) => {
      const linkedTurn = mergedDialogue.turns[moment.turn_index];
      const speaker = linkedTurn ? linkedTurn.speaker : 'UNKNOWN';
      const turnLink = createTurnLink(moment.turn_index, speaker);
      return {
        turnIndex: moment.turn_index,
        description: moment.description,
        dialogueSnippet: moment.dialogue_snippet,
        relevantEvents: (moment.relevant_events || []).map(formatModalityEvent),
        imageCorrelationNotes: moment.image_correlation_notes,
        turnLink: turnLink,
      };
    }),
    therapeuticObservations: analysisResult.therapeutic_observations.map((obs: TherapeuticObservation) => {
      const linkedTurn = mergedDialogue.turns[obs.turn_index];
      const speaker = linkedTurn ? linkedTurn.speaker : 'UNKNOWN';
      const turnLink = createTurnLink(obs.turn_index, speaker);
      let evidenceLinks: ReportEvidenceLink[] = [];
      if (obs.evidence?.pointers && obs.evidence.pointers.length > 0) {
        const uniqueTurnIndices = [...new Set(obs.evidence.pointers.map(p => p.turn_index))];
        evidenceLinks = uniqueTurnIndices.sort((a, b) => a - b).map(idx => {
          const evSpeaker = mergedDialogue.turns[idx]?.speaker || 'UNKNOWN';
          return createTurnLink(idx, evSpeaker);
        });
      }
      return {
        turnIndex: obs.turn_index,
        observation: obs.observation,
        evidenceSummary: obs.evidence?.summary,
        evidenceLinks: evidenceLinks,
        turnLink: turnLink,
      };
    }),
  };

  // Construct the final ReportModel
  return {
    title: "Session Analysis Report",
    backgroundContext: backgroundContext,
    dialogue: reportDialogue,
    timelineData: timelineData, // Assign the timeline data object
    analysis: reportAnalysis,
  };
}

// NEW: Function to render TimelineData into Mermaid string
function renderTimelineDataToMermaid(timelineData: TimelineData): string {
  let mermaidString = '```mermaid\ntimeline\n';
  mermaidString += `    title ${timelineData.title}\n`;

  timelineData.sections.forEach(section => {
    mermaidString += `    section ${section.title}\n`;
    section.events.forEach(event => {
      // Format speaker for display (e.g., PATIENT -> P)
      const speakerInitial = event.speaker.startsWith('THER') ? 'T' : 'P';
      let eventLine = `        Turn ${event.turn_index + 1} (${speakerInitial}) : ${event.summary}`;
      if (event.markers && event.markers.length > 0) {
        eventLine += ` ; ${event.markers.join(' ; ')}`;
      }
      mermaidString += eventLine + '\n';
    });
  });

  mermaidString += '```';
  return mermaidString;
}

// Renders the ReportModel into a GitHub Flavored Markdown string
function renderReportModelToMarkdown(model: ReportModel): string {
  let md = `# ${model.title}\n\n`;

  // Background Context
  md += `## Background Context\n\n`;
  md += `${model.backgroundContext}\n\n`;

  // Dialogue Transcript
  md += `## Dialogue Transcript\n\n`;
  model.dialogue.forEach(turn => {
    const turnIndex = parseInt(turn.id.split('-')[1]) - 1; // Get 0-based index from ID
    md += `#### Turn ${turnIndex + 1} (${turn.speaker})\n\n`; // Use H4 for turns
    md += `> ${turn.utterance}\n\n`;
    if (turn.events.length > 0) {
      md += `_Modality Events:_\n\n`;
      md += turn.events.map(eventText =>
        `- ${eventText}`
      ).join('\n') + '\n\n';
    }
    md += '---\n\n';
  });
  md = md.trimEnd() + '\n\n';

  // Insert Mermaid Timeline (Rendered from data)
  md += `## Session Timeline\n\n`;
  const mermaidContent = renderTimelineDataToMermaid(model.timelineData);
  md += `${mermaidContent}\n\n`; // Add the rendered mermaid string

  // Analysis Section
  md += `## Session Analysis\n\n`;

  // Overall Summary
  md += `### Overall Summary\n\n`;
  md += `${model.analysis.overallSummary}\n\n`;

  // Identified Themes
  md += `### Identified Themes\n\n`;
  if (model.analysis.identifiedThemes.length === 0) {
    md += `_No major themes identified._\n\n`;
  } else {
    model.analysis.identifiedThemes.forEach(theme => {
      md += `- **Theme:** ${theme.theme}\n`;
      if (theme.evidenceSummary) {
        md += `  - _Summary:_ ${theme.evidenceSummary}\n`;
      }
      if (theme.evidenceLinks.length > 0) {
        const links = theme.evidenceLinks.map(link => `[${link.text}](${link.targetId})`).join(', ');
        md += `  - _Evidence:_ ${links}\n`;
      }
    });
    md += '\n';
  }

  // Key Moments
  md += `### Key Moments\n\n`;
  if (model.analysis.keyMoments.length === 0) {
    md += `_No key moments identified._\n\n`;
  } else {
    model.analysis.keyMoments.forEach(moment => {
      md += `- **Moment (related to [${moment.turnLink.text}](${moment.turnLink.targetId})):** ${moment.description}\n`;
      if (moment.dialogueSnippet) {
        md += `  - _Dialogue Snippet:_ "${moment.dialogueSnippet}"\n`;
      }
      if (moment.relevantEvents.length > 0) {
        md += `  - _Relevant Events:_\n`;
        moment.relevantEvents.forEach(eventStr => md += `    - ${eventStr}\n`);
      }
      if (moment.imageCorrelationNotes) {
        md += `  - _Image Notes:_ ${moment.imageCorrelationNotes}\n`;
      }
    });
    md += '\n';
  }

  // Therapeutic Observations
  md += `### Therapeutic Observations\n\n`;
  if (model.analysis.therapeuticObservations.length === 0) {
    md += `_No specific therapeutic observations noted._\n\n`;
  } else {
    model.analysis.therapeuticObservations.forEach(obs => {
      md += `- **Observation (related to [${obs.turnLink.text}](${obs.turnLink.targetId})):** ${obs.observation}\n`;
      if (obs.evidenceSummary) {
        md += `  - _Evidence Summary:_ ${obs.evidenceSummary}\n`;
      }
      if (obs.evidenceLinks && obs.evidenceLinks.length > 0) {
        const links = obs.evidenceLinks.map(link => `[${link.text}](${link.targetId})`).join(', ');
        md += `  - _Evidence Links:_ ${links}\n`;
      }
    });
    md += '\n';
  }

  return md.trim() + '\n';
}

// Update generateMarkdownReport signature to accept TimelineData
function generateMarkdownReport(
  backgroundContext: string,
  mergedDialogue: Dialogue,
  analysisResult: SessionAnalysis,
  timelineData: TimelineData // Accept timeline data object
): string {
  const reportModel = mapBamlToReportModel(backgroundContext, mergedDialogue, analysisResult, timelineData);
  const markdownContent = renderReportModelToMarkdown(reportModel);
  return markdownContent;
}

// ----- End Markdown Report Generation Functions -----

// Parse command-line arguments
program.parse(process.argv);

// Handle cases where no command is provided
if (!program.args.length) {
 // Uncomment the next line if you want to show help by default
 // program.help();
} 