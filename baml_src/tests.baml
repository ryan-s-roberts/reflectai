// -------- Test Cases --------

// Test case for synthesizing a session based on a complex client profile.
test SynthesizeSopranoStyleSession {
  functions [SynthesizeTherapySession] // Target ONLY the dialogue synthesis function
  args {
    background_context #"
      Client is a middle-aged male presenting with recurrent panic attacks and generalized anxiety. Reports significant stress stemming from complex family dynamics (including demanding parental figures and challenging adolescent children) and leadership responsibilities within a high-pressure, non-traditional business environment. Expresses difficulty managing anger and frustration, often resorting to externalizing blame. History suggests potential alexithymia and resistance to exploring deeper emotional vulnerability. Treatment goals include developing healthier coping mechanisms for anxiety and anger, improving insight into interpersonal patterns, and managing stress related to occupational demands. Client sometimes uses sessions to process recent stressful events related to his work and family life.
    "#
    session_length_minutes 5
  }
}

// Test case for synthesizing visual events based on a static dialogue fixture.
test SynthesizeVisualEventsFromFixture {
  functions [SynthesizeVisualEvents] // Target ONLY the visual event synthesis function
  args {
    background_context #"
      Client is a middle-aged male presenting with recurrent panic attacks and generalized anxiety. Reports significant stress stemming from complex family dynamics (including demanding parental figures and challenging adolescent children) and leadership responsibilities within a high-pressure, non-traditional business environment. Expresses difficulty managing anger and frustration, often resorting to externalizing blame. History suggests potential alexithymia and resistance to exploring deeper emotional vulnerability. Treatment goals include developing healthier coping mechanisms for anxiety and anger, improving insight into interpersonal patterns, and managing stress related to occupational demands. Client sometimes uses sessions to process recent stressful events related to his work and family life.
    "#
    dialogue {
      turns [
        {
          speaker "PATIENT"
          utterance "I had another one of those situations at work yesterday where everything just got completely overwhelming. One of my direct reports messed up this major client presentation and I just... I completely lost it in the meeting."
          timestamp_ms 0
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Rapid hand gestures"
              confidence 0.9
            }
            {
              source "AUDIO_EMOTION"
              description "Increased speech rate"
              confidence 0.85
            }
          ]
        }
        {
          speaker "THERAPIST"
          utterance "I can hear how intensely this situation affected you. Before we go further into what happened, could you help me understand what you were feeling in your body during that moment?"
          timestamp_ms 15000
          events [
            {
              source "GAZE_DIRECTION"
              description "Maintains steady eye contact"
              confidence 0.95
            }
          ]
        }
        {
          speaker "PATIENT"
          utterance "In my body? I don't know, I was just angry. I mean my heart was racing and my face felt hot but honestly I was more focused on how incompetent they were being and how it made me look bad."
          timestamp_ms 28000
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Crosses arms"
              confidence 0.9
            }
            {
              source "GAZE_DIRECTION"
              description "Glances away briefly"
              confidence 0.85
            }
          ]
        }
        {
          speaker "THERAPIST"
          utterance "Those physical sensations - racing heart, hot face - sound similar to what you've described experiencing during panic attacks. I'm wondering if you noticed any anxiety mixing with the anger?"
          timestamp_ms 42000
          events [
            {
              source "AUDIO_EMOTION"
              description "Gentle, measured tone"
              confidence 0.9
            }
          ]
        }
        {
          speaker "PATIENT"
          utterance "I mean maybe yeah but it's different. This was justified, they really screwed up. It's like at home with the kids too - when things go wrong I have to be the one to fix everything and sometimes it just builds up until I snap."
          timestamp_ms 56000
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Leans forward slightly"
              confidence 0.8
            }
            {
              source "FACIAL_EXPRESSION"
              description "Slight frown"
              confidence 0.85
            }
          ]
        }
        {
          speaker "THERAPIST"
          utterance "I'm hearing a pattern of feeling overwhelmed by responsibility, both at work and home. When the pressure builds, it seems to trigger both anger and anxiety. What would it be like to notice those early physical warning signs as signals to use some of our coping strategies?"
          timestamp_ms 73000
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Open palm gesture"
              confidence 0.9
            }
          ]
        }
        {
          speaker "PATIENT"
          utterance "Yeah I guess I could've taken a break or something instead of blowing up. It's just hard in the moment to think about that stuff when everything feels so urgent."
          timestamp_ms 88000
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Shoulders relax slightly"
              confidence 0.8
            }
            {
              source "GAZE_DIRECTION"
              description "Re-establishes eye contact"
              confidence 0.9
            }
          ]
        }
      ]
    }
  }
}

// Test case for analyzing a session based on a static dialogue fixture merged with visual events.
test AnalyzeSessionMultimodalFromFixture {
  functions [AnalyzeSessionMultimodal] // Target the multimodal analysis function
  args {
    background_context #"
      Client is a middle-aged male presenting with recurrent panic attacks and generalized anxiety. Reports significant stress stemming from complex family dynamics (including demanding parental figures and challenging adolescent children) and leadership responsibilities within a high-pressure, non-traditional business environment. Expresses difficulty managing anger and frustration, often resorting to externalizing blame. History suggests potential alexithymia and resistance to exploring deeper emotional vulnerability. Treatment goals include developing healthier coping mechanisms for anxiety and anger, improving insight into interpersonal patterns, and managing stress related to occupational demands. Client sometimes uses sessions to process recent stressful events related to his work and family life.
    "#
    dialogue { // Full 8-turn dialogue merged with visual observations for PATIENT turns (indices 1, 3, 5, 7)
      turns [
        {
          // Turn 0 (Therapist)
          speaker "THERAPIST"
          utterance "Last time we met, you mentioned experiencing a panic attack during your team meeting. How have things been since then?"
          timestamp_ms 0
          events [
            {
              source "GAZE_DIRECTION"
              description "Maintains steady eye contact"
              confidence 0.9
            }
          ]
        }
        {
          // Turn 1 (Patient)
          speaker "PATIENT"
          utterance "Yeah well it's been... I mean the team's still not performing and my father keeps calling about the family business stuff and I just... I can feel my chest getting tight just thinking about it all"
          timestamp_ms 8000
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Hand moves to chest"
              confidence 0.95
            }
            {
              source "AUDIO_EMOTION"
              description "Increasing tension in voice"
              confidence 0.85
            }
            // Added visual events (corresponding to original visual fixture index 0)
            {
              source "VISUAL_ANALYSIS"
              description "Sits forward on edge of chair"
              confidence 0.85
            }
            {
              source "VISUAL_ANALYSIS"
              description "Jaw muscles tighten"
              confidence 0.75
            }
          ]
        }
        {
          // Turn 2 (Therapist)
          speaker "THERAPIST"
          utterance "I notice you're touching your chest as you describe this. Can you tell me more about what you're experiencing in your body right now?"
          timestamp_ms 20000
          events [
            {
              source "AUDIO_SPEECH_FEATURES"
              description "Speaking at slower, measured pace"
              confidence 0.9
            }
          ]
        }
        {
          // Turn 3 (Patient)
          speaker "PATIENT"
          utterance "It's like this pressure building up and honestly I'm just angry because nobody seems to get it they all just want more and more from me and I can't"
          timestamp_ms 28000
          events [
            {
              source "BODY_POSE_GESTURE"
              description "Fists clench briefly"
              confidence 0.85
            }
            {
              source "GAZE_DIRECTION"
              description "Glances away"
              confidence 0.9
            }
            // Added visual events (corresponding to original visual fixture index 2)
            {
              source "VISUAL_ANALYSIS"
              description "Shakes head slightly"
              confidence 0.85
            }
            {
              source "VISUAL_ANALYSIS"
              description "Purses lips"
              confidence 0.8
            }
          ]
        }
        {
          // Turn 4 (Therapist)
          speaker "THERAPIST"
          utterance "It sounds overwhelming - trying to meet everyone's expectations while dealing with these intense physical sensations. What would it be like to acknowledge that you're carrying a lot right now?"
          timestamp_ms 40000
          events [
            {
              source "AUDIO_EMOTION"
              description "Gentle, empathetic tone"
              confidence 0.95
            }
          ]
        }
        {
          // Turn 5 (Patient)
          speaker "PATIENT"
          utterance "I mean I guess... but I should be able to handle this I'm supposed to be the one in charge here"
          timestamp_ms 52000
          events [
            {
              source "FACIAL_EXPRESSION"
              description "Slight frown"
              confidence 0.8
            }
            {
              source "BODY_POSE_GESTURE"
              description "Shoulders tense"
              confidence 0.85
            }
            // Added visual events (corresponding to original visual fixture index 4)
            {
              source "VISUAL_ANALYSIS"
              description "Taps finger on armrest"
              confidence 0.85
            }
            {
              source "VISUAL_ANALYSIS"
              description "Straightens posture"
              confidence 0.8
            }
          ]
        }
        {
          // Turn 6 (Therapist)
          speaker "THERAPIST"
          utterance "Let's explore that 'should.' Even leaders need support sometimes. What would you say to a colleague facing similar pressures?"
          timestamp_ms 60000
          events [
            {
              source "GAZE_DIRECTION"
              description "Leans slightly forward"
              confidence 0.9
            }
          ]
        }
        {
          // Turn 7 (Patient)
          speaker "PATIENT"
          utterance "I'd probably... huh... I guess I wouldn't expect them to handle everything alone like this"
          timestamp_ms 68000
          events [
            {
              source "AUDIO_SPEECH_FEATURES"
              description "Speech pace slows"
              confidence 0.85
            }
            {
              source "BODY_POSE_GESTURE"
              description "Shoulders relax slightly"
              confidence 0.8
            }
            // Added visual events (corresponding to original visual fixture index 6)
            {
              source "VISUAL_ANALYSIS"
              description "Touches chin briefly"
              confidence 0.75
            }
            {
              source "VISUAL_ANALYSIS"
              description "Nods slightly"
              confidence 0.85
            }
          ]
        }
      ]
    }
  }
}

