// -------- Core Data Types --------

enum SpeakerType {
  PATIENT @alias("k1") @description("The person receiving therapy")
  THERAPIST @alias("k2") @description("The person providing therapy")
}

enum EventSourceType {
  AUDIO_EMOTION @alias("m1") @description("Emotion inferred from vocal tone")
  AUDIO_SPEECH_FEATURES @alias("m2") @description("Characteristics like speech rate, pitch, pauses")
  FACIAL_EXPRESSION @alias("m3") @description("Detected facial muscle movements (e.g., smile, frown, Action Units)")
  BODY_POSE_GESTURE @alias("m4") @description("Posture changes, fidgeting, hand movements")
  GAZE_DIRECTION @alias("m5") @description("Direction the person is looking")
  PHYSIOLOGICAL_SENSOR @alias("m6") @description("Data from sensors like heart rate, GSR (if applicable)")
  VISUAL_ANALYSIS @alias("m7") @description("Observations inferred from images/video analysis (e.g., specific expressions, gestures)")
}

class ModalityEvent {
  source EventSourceType @description("Identifier for the system or model that generated the event.")
  description string @description("Textual description of the detected event (e.g., 'High vocal arousal', 'Patient smiling').")
  confidence float? @description("Optional confidence score (e.g., 0.0 to 1.0) associated with the event detection.")
}

class DialogueTurn {
  speaker SpeakerType
  utterance string @description("The exact text spoken by the speaker.")
  timestamp_ms int? @description("Optional timestamp in milliseconds from the start of the dialogue.")
  events ModalityEvent[] @description("List of events from other modalities detected during this dialogue turn.")
}

class Dialogue {
  turns DialogueTurn[] @description("An ordered list of dialogue turns, representing the conversation flow.")
} 