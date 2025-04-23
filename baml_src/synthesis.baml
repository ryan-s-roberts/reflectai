// -------- Synthesis Functions --------

// Function to synthesize a realistic therapy dialogue session.
// Takes background context and desired length as input.
// Generates alternating patient/therapist turns with utterances and associated modality events.
function SynthesizeTherapySession(
  background_context: string @description("Information about the patient, the therapeutic goals, or previous sessions."),
  session_length_minutes: int @description("Guideline for approximate desired length of the synthesized session in minutes. Focus on narrative completeness over strict time adherence.")
) -> Dialogue {
  client CustomSonnet
  prompt #"
    Synthesize a realistic, **didactic** therapy dialogue session between a PATIENT and a THERAPIST, suitable for clinical training or analysis.

    Background Context:
    {{ background_context }}

    Guideline Session Length: {{ session_length_minutes }} minutes (focus on completing a meaningful interaction arc rather than hitting an exact time).

    Instructions:
    1.  **Think step-by-step:** First, outline your plan for the session's **narrative arc**. Aim for a clear beginning (e.g., check-in, setting agenda), middle (e.g., exploring a core issue, working through a specific technique), and end (e.g., summarizing, planning next steps). The session should **illustrate key dynamics or therapeutic techniques** relevant to the background context.
    2.  Generate a sequence of dialogue turns, strictly alternating between PATIENT and THERAPIST, following your narrative plan.
    3.  The dialogue should be coherent and reflect a **plausible and instructive** therapeutic interaction.
    4.  Therapist utterances should demonstrate **clear therapeutic techniques** (e.g., active listening, empathy, validation, Socratic questioning, reframing, psychoeducation) appropriate to the context and chosen narrative arc.
    5.  Patient utterances should reflect plausible emotional states, responses to the therapist, and descriptions of experiences or thoughts, **clearly linking to the background context and treatment goals**. Aim for natural speech patterns, potentially resembling raw speech-to-text output (e.g., less formal punctuation, run-ons) rather than perfectly structured written sentences. Avoid literary devices like explicit descriptions of pauses (e.g., '*long pause*').
    6.  For EACH dialogue turn, include a list of 1-3 relevant modality events (can be empty). These events should subtly enhance the understanding of the interaction.
    7.  Modality events should reflect reasonable, subtle, **atomic, and objective** human behaviors detected by hypothetical sensors corresponding to EventSourceType (e.g., m1 for vocal tone shifts, m2 for speech features, m3 for smiles/frowns, m4 for fidgeting/posture changes, m5 for eye contact shifts). Descriptions should be **simple observations** (e.g., "Shifts gaze downward", "Taps fingers", "Slight frown", "Hand touches chest") and **MUST NOT interpret the behavior or link it to the dialogue content** (e.g., avoid "Hand moving to chest *while describing sensation*"). Avoid overly dramatic or non-subtle events. **Crucially, DO NOT generate events with the source `VISUAL_ANALYSIS` (alias `m7`); these will be synthesized separately.**
    8.  After outlining your plan and generating the dialogue, ensure the final output structure strictly aligns with the BAML `Dialogue` definition.

    Plan Outline (Focus on Narrative Arc & Key Interactions):
    [LLM outlines its plan here...]

    Synthesized Didactic Dialogue:
    [LLM generates dialogue here...]

    {{ ctx.output_format }}
  "#
}

// Function to synthesize visual events based *only* on dialogue context.
// This is used when actual images are not available.
// Output events source is VISUAL_ANALYSIS and can be richer/less atomic, like image-based analysis.
function SynthesizeVisualEvents(
  background_context: string @description("Information about the patient, therapeutic goals, previous sessions, etc."),
  dialogue: Dialogue // Assumes dialogue *does not* yet contain VISUAL_ANALYSIS events
) -> TurnSpecificVisualEvents[] { // Outputs the same structure as AnalyzeVisualInput
  client CustomSonnet
  prompt #"""
    Act as a synthesizer of plausible visual behaviors inferred *solely from dialogue context*. Your task is to review the provided dialogue and generate potential **visual modality events** (source: VISUAL_ANALYSIS) for each PATIENT turn, simulating what might be observed if video were present, but without access to actual images.

    Background Context:
    {{ background_context }}

    Dialogue Session (for context):
    {{ dialogue | tojson }}

    Instructions:
    1.  **Think step-by-step:** Iterate through each PATIENT turn in the provided dialogue. For each patient turn (`turn_index`):
        *   Review the patient's utterance and any existing non-visual modality events within that turn.
        *   Consider the **immediately preceding THERAPIST turn** (`turn_index - 1`) and the patient's response as primary context.
        *   Plan 1-2 plausible visual observations (e.g., related to gaze, posture, facial expression, gestures) that might occur during this patient turn, consistent with the dialogue context.
    2.  **Generate Visual Events:** For each patient turn analyzed, create a list of `ModalityEvent` objects:
        *   Set the `source` to `VISUAL_ANALYSIS`.
        *   Use the `description` field to detail **meaningful visual observations inferred from the dialogue context**. Descriptions should be objective but can integrate multiple related visual elements (similar to image-based analysis, e.g., "Leans forward, looking intently at therapist", "Shakes head, looking down"). Avoid subjective interpretations of emotion unless strongly suggested by the dialogue context.
        *   Assign a plausible `confidence` score (perhaps lower on average than image-based analysis due to lack of direct visual evidence).
    3.  **Structure Output:** Generate a JSON list (array) where each element is an object strictly adhering to the `TurnSpecificVisualEvents` schema provided by `{{ ctx.output_format }}`. Each object must contain the patient `turn_index` and its corresponding list of generated `ModalityEvent` objects (`visual_events`).
    4.  If no specific visual behaviors seem plausible or directly suggested by the dialogue for a given patient turn, do not include an entry for that `turn_index` in the output list.

    {{ ctx.output_format }} // Expecting schema for list<TurnSpecificVisualEvents>

    Analysis Plan (Chain of Thought):
    [LLM outlines its plan for synthesizing visual events turn-by-turn...]

    Synthesized Visual Events (Grouped by Turn):
  """#
}