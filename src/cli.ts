#!/usr/bin/env node
import { Command } from 'commander';
import { b } from './baml_client/index';
import type { Dialogue, DialogueTurn, ModalityEvent, TurnSpecificVisualObservations, VisualObservation, SessionAnalysis } from './baml_client/types';
import { EventSourceType } from './baml_client/types';
import { BamlErrors } from '@boundaryml/baml';

const program = new Command();

program
  .name('shrink-cli')
  .description('CLI tool for interacting with BAML therapy session synthesis and analysis')
  .version('1.0.0');

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
    console.log('Starting session synthesis...');
    try {
      // 1. Synthesize base dialogue
      const dialogue: Dialogue = await b.SynthesizeTherapySession(
        options.backgroundContext,
        options.sessionLength
      );
      console.log(`Synthesized initial dialogue with ${dialogue.turns.length} turns.`);

      // 2. Synthesize visual observations
      const visualObservationsList: TurnSpecificVisualObservations[] = await b.SynthesizeVisualEvents(
        options.backgroundContext,
        dialogue
      );
      console.log(`Synthesized visual observations for ${visualObservationsList.length} turns.`);

      // 3. Merge visual observations into the dialogue
      const mergedDialogue: Dialogue = mergeVisualEvents(dialogue, visualObservationsList);
      console.log('Merged visual observations into dialogue.');

      // 4. Analyze the merged dialogue
      console.log('Starting multimodal analysis...');
      const analysisResult: SessionAnalysis = await b.AnalyzeSessionMultimodal(
        mergedDialogue,
        options.backgroundContext
      );
      console.log('Analysis complete.');

      // 5. Pretty-print the result
      console.log('\n--- Session Analysis Result ---');
      console.log(JSON.stringify(analysisResult, null, 2));

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
 * Merges synthesized visual observations into the corresponding turns of a dialogue object.
 */
function mergeVisualEvents(
  dialogue: Dialogue,
  visualObservationsList: TurnSpecificVisualObservations[]
): Dialogue {
  // Create a deep copy to avoid modifying the original dialogue object
  const updatedDialogue: Dialogue = JSON.parse(JSON.stringify(dialogue));

  // Create a map for quick lookup of visual observations by turn index
  const visualObservationsMap = new Map<number, VisualObservation[]>();
  visualObservationsList.forEach(item => {
    visualObservationsMap.set(item.turn_index, item.visual_observations);
  });

  updatedDialogue.turns.forEach((turn: DialogueTurn, index: number) => {
    const observations = visualObservationsMap.get(index);
    if (observations && observations.length > 0) {
      // Ensure the events array exists
      if (!turn.events) {
        turn.events = [];
      }
      // Map VisualObservation to ModalityEvent and add
      const visualEvents: ModalityEvent[] = observations.map((obs: VisualObservation) => ({
        source: EventSourceType.VISUAL_ANALYSIS, // Use enum member
        description: obs.description,
        confidence: obs.confidence ?? null, // Handle optional confidence
      }));
      turn.events.push(...visualEvents);
    }
  });

  return updatedDialogue;
}


// Parse command-line arguments
program.parse(process.argv);

// Handle cases where no command is provided
if (!program.args.length) {
 // Uncomment the next line if you want to show help by default
 // program.help();
} 