// -------- Structures for Analysis Output --------

// Helper class to associate an image with a specific patient turn index.
class PatientImageTurn {
  turn_index int @description("The index in dialogue.turns corresponding to this image. Must be a patient turn.")
  image string // Temporarily changed from 'image' to 'string' for testing
}

// Represents a recurring theme identified in the session.
class SessionTheme {
  theme string @description("A concise description of the identified theme (e.g., 'Anxiety about work', 'Difficulty with boundaries').")
  evidence_turn_indices int[] @description("Indices of dialogue turns supporting this theme.")
  evidence_summary string? @description("Optional brief summary justifying the theme based on dialogue/events within the referenced turns.")
}

// Represents a significant moment or observation during the session.
class KeyMoment {
  turn_index int @description("The index of the primary dialogue turn related to this moment.")
  description string @description("Description of the key moment or observation (e.g., 'Patient expressed insight into pattern', 'Therapist used reframing technique', 'Discrepancy noted between verbal report and facial expression').")
  dialogue_snippet string? @description("Optional relevant snippet of text from the dialogue turn.")
  relevant_events ModalityEvent[] @description("Modality events from this turn that support the observation.")
  image_correlation_notes string? @description("Observations based on the image for this turn (if patient turn and image provided), noting correlation or discrepancy with dialogue/events.")
}

// Structure to hold evidence for an observation.
class EvidencePointer {
  turn_index int @description("Index of the turn containing the referenced event.")
  source EventSourceType @description("The source type of the referenced event.")
  event_index int @description("Index of the specific event within the turn's events list for the given source.")
}

class EvidenceReference {
  summary string @description("Textual summary of the supporting evidence (e.g., 'Patient stated feeling anxious', 'Therapist provided psychoeducation', 'Observed increased fidgeting').")
  pointers EvidencePointer[]? @description("Optional list of specific event pointers supporting the evidence summary.")
}

// Represents a specific therapeutic technique or approach observed.
class TherapeuticObservation {
  turn_index int @description("The index of the dialogue turn where the observation primarily applies.")
  observation string @description("Description of the therapeutic technique used or a clinical observation about patient progress/process (e.g., 'Used Socratic questioning', 'Patient demonstrated improved emotional regulation', 'Explored cognitive distortion').")
  evidence EvidenceReference? @description("Structured evidence supporting the observation.")
}

class TurnSpecificVisualEvents {
  turn_index int @description("The index of the patient dialogue turn these visual events belong to.")
  visual_events ModalityEvent[] @description("List of VISUAL_ANALYSIS events for this turn.")
}

class SessionAnalysis {
  overall_summary string @description("A brief summary of the session's key dynamics, progress, and areas for future focus.")
  identified_themes SessionTheme[] @description("List of major themes discussed during the session.")
  key_moments KeyMoment[] @description("List of significant moments or observations linking dialogue, events, and images.")
  therapeutic_observations TherapeuticObservation[] @description("List of observations related to therapeutic process and techniques.")
}

// -------- Visual Analysis Function (Stage 1) --------

// Function to analyze visual input (images) in context of dialogue turns.
function AnalyzeVisualInput(
  dialogue: Dialogue,
  background_context: string @description("Information about the patient, therapeutic goals, previous sessions, etc."),
  patient_turn_images: PatientImageTurn[]?
) -> TurnSpecificVisualEvents[] {
  client CustomSonnet // Changed from CustomGPT4o
  prompt #"""
    Act as an **objective visual observation model**. Your task is to analyze the provided patient images in the context of their corresponding dialogue turns and associated modality events. Generate new modality events describing **specific, observable visual behaviors**.

    Background Context:
    {{ background_context }}

    Dialogue Session (for context):
    {{ dialogue | tojson }}

    Patient Turn Images:
    // Provided as a list of objects, each with 'turn_index' and 'image'.
    {{ patient_turn_images | map(describe_element) }} 

    Instructions:
    1.  **Think step-by-step:** For each image provided in `patient_turn_images`:
        *   Identify the corresponding `turn_index` (which is a PATIENT turn).
        *   Review the dialogue utterance and all existing modality events (audio, etc.) **within that specific patient turn (`turn_index`)** to understand the immediate multi-modal context.
        *   Analyze the visual content of the image(s) for that turn.
        *   **Reasoning:** Consider how the patient's visual behavior might relate to the **immediately preceding THERAPIST turn** or earlier dialogue. Note this reasoning briefly, but focus generated events on direct observation.
    2.  **Generate Visual Events:** For each patient turn analyzed, create a list of new `ModalityEvent` objects:
        *   Use the `description` field to detail **specific, observable visual behaviors**...
        *   Assign a plausible `confidence` score...
    3.  Focus ONLY on generating `ModalityEvent` objects describing visual observations.
    4.  **Structure Output:** For each `turn_index` processed that has generated visual events, create a `TurnSpecificVisualEvents` object containing that `turn_index` and the corresponding list of generated `ModalityEvent` objects (`visual_events`). Output the final result as a list of these `TurnSpecificVisualEvents` objects. Adhere strictly to the BAML schema.

    {{ ctx.output_format }} // Should be format for list<TurnSpecificVisualEvents>

    Analysis Plan (Chain of Thought):
    [LLM outlines its visual analysis plan here...]

    Generated Visual Events:
  """#
}

// -------- Overall Analysis Function (Stage 2) --------

// Function to perform overall analysis of the therapy session using all modalities.
// Assumes the input dialogue contains events from all sources, including VISUAL_ANALYSIS.
function AnalyzeSessionMultimodal(
  dialogue: Dialogue, // Enriched dialogue with events from all sources
  background_context: string @description("Information about the patient, therapeutic goals, previous sessions, etc.")
) -> SessionAnalysis {
  client CustomSonnet // Changed from CustomGPT4o
  prompt #"""
    Act as an expert clinical analyst adhering to **best practices for objective and comprehensive therapy documentation**. Your task is to analyze the provided dialogue transcript, associated modality events (including audio, visual, etc.), and background context to produce a structured clinical summary.

    Background Context:
    {{ background_context }}

    Enriched Dialogue Session (includes VISUAL_ANALYSIS events):
    {{ dialogue | tojson }}

    Instructions:
    1.  **Think step-by-step:** First, outline your analysis plan. Review the context and the full dialogue flow, focusing on **specific, observable behaviors and precisely described emotional expressions** across all modalities. Note potential themes, key interactions, therapist techniques (e.g., validation, Socratic questioning, psychoeducation), client strengths/progress, and challenges based on standard therapeutic documentation practices. Consider the temporal nature of the dialogue.
    2.  **Identify Major Themes:** Determine the main recurring topics or underlying issues discussed (populate `identified_themes`). Phrase themes neutrally. For each theme, provide supporting `evidence_turn_indices` and a brief `evidence_summary` justifying the theme based on specific dialogue or modality patterns within those turns.
    3.  **Pinpoint Key Moments:** Highlight significant interactions using **objective descriptions**. For each moment (populate `key_moments`):
        *   Reference the specific dialogue turn index where the moment culminates or is most evident.
        *   In the `description`, clearly describe the moment, integrating specific observations from all available modalities. **Also note any clear causal links or reactions to preceding turns (e.g., "Patient became visibly withdrawn following therapist's question in previous turn about...").**
        *   Include relevant dialogue snippets and modality events (`relevant_events`) from the primary turn index as evidence.
    4.  **Note Therapeutic Observations:** Document specific therapist techniques observed or clinical insights about the patient's process, **including strengths and progress** (populate `therapeutic_observations`). For each observation:
        *   Link it to the primary `turn_index`.
        *   Phrase observations objectively (e.g., "Therapist utilized reframing technique", "Patient identified alternative thought", "Patient demonstrated use of coping skill discussed previously", "Patient expressed insight into emotional trigger").
        *   Provide structured `evidence` using the `EvidenceReference` class: include a concise textual `summary` of the **observable evidence** and optionally list specific `pointers` referencing the supporting turn, source, and event index. Ensure pointers are valid.
    5.  **Summarize:** Provide a concise `overall_summary` covering the session's key dynamics, **progress made, client strengths noted**, and potential areas for future focus, maintaining a **neutral, objective tone**.
    6.  Ensure the final output strictly follows the BAML `SessionAnalysis` structure defined below.

    {{ ctx.output_format }}

    Analysis Plan (Chain of Thought):
    [LLM outlines its analysis plan here...]

    Structured Session Analysis:
  """#
} 