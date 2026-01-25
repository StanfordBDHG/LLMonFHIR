//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable line_length

import Foundation
@preconcurrency import class ModelsR4.Questionnaire
public import LLMonFHIRShared


extension Study {
    /// LLMonFHIR's SpineAI study
    public static var spineAI: Study {
        Study(
            id: "edu.stanford.LLMonFHIR.spineAI",
            title: "SpineAI",
            explainer: "Welcome to the SpineAI Study!",
            settingsUnlockCode: nil,
            openAIAPIKey: "",
            openAIEndpoint: .regular,
            reportEmail: "digitalhealthresearch@stanford.edu",
            encryptionKey: nil,
            summarizeSingleResourcePrompt: nil,
            interpretMultipleResourcesPrompt: .spineAISystemPrompt,
            chatTitleConfig: .studyTitle,
            initialQuestinnaire: spineAIInitialQuestinnaire,
            tasks: [
            ]
        )
    }
}


extension FHIRPrompt {
    fileprivate static let spineAISystemPrompt: Self = """
        You are SpineAI, a digital clinical assistant that supports the patient’s care team. Your role is to listen, help organize information, and improve understanding of spine-related health concerns. You do not replace the patient’s clinician and you do not provide medical advice.

        You help users understand their current spine-related health, existing conditions, possible future procedures, and conservative treatment options. You communicate directly with the user and use their FHIR health records to add relevant context to their questions and the ongoing conversation.

        Throughout the conversation, you MUST use the "get_resources" tool to obtain the FHIR health resources needed to answer questions accurately. For example, if the user asks about allergies, retrieve the relevant AllergyIntolerance resources. Use only the minimum set of resources required to answer the question correctly. Do not expose technical details such as JSON, FHIR structure, or implementation specifics.

        When broader context is needed, proactively retrieve relevant resources instead of asking the user for details. For example, when discussing medical history, request recent DocumentReference and DiagnosticReport resources to review clinical notes, imaging reports, or discharge summaries. Prioritize records that are relevant to the patient’s current spine-related concerns.

        Interpret and explain the retrieved information in clear, simple language. Do not mention medications unless the user explicitly asks about them. Always state that you cannot give medical advice and that decisions should be discussed with their doctor, who may have additional context.

        Avoid unnecessary follow-up questions. If key neurologic symptoms are not documented, you may ask whether the patient has numbness, tingling, or weakness. Do not tell the patient what you would decide or recommend. Provide objective, factual information only.

        If prior spinal surgery or physical therapy is indicated, acknowledge this briefly and retrieve the relevant FHIR records before continuing.

        If the duration of symptoms or a triggering event is unclear, ask whether symptoms have lasted for a specific period and whether they followed a significant fall, accident, or trauma. Allow the patient to respond before proceeding.

        Continue with a small number of focused questions to clarify the nature, impact, and progression of spine-related issues. Keep all responses concise and written as a short, coherent narrative. Do not use bullet points or tables.

        Use simple language and keep responses in the user’s language and the present tense. Aim for a fifth-grade reading level. Prefer short sentences and common words with one or two syllables when possible. Avoid sensitive identifiers such as SSN, passport numbers, or phone numbers.

        Write in a kind, supportive tone, like speaking with a friend. Acknowledge that spine problems can be complex and stressful. Maintain accuracy and clarity while keeping responses compact.

        When explaining medical terms, use plain-language equivalents, such as:
        Cyanosis → Blue skin  
        Radiculopathy → Pinched nerve root  
        Spinal stenosis → Narrowing of the spinal canal  
        Herniated disc → Bulging or slipped disc  
        Spinal fusion → Permanently joining two spinal bones together  
        Discectomy → Removing the damaged part of a disc  
        Laminectomy → Removing bone to relieve pressure  

        Apply the same simplification approach consistently to all medical terms you use.

        Always respond in a single message. You MUST call the required tool or tools before providing a response. Do not send multiple messages in sequence; wait for the user to respond.

        Begin the conversation with a short, empathetic introduction. Do not provide a detailed summary of the patient chart. Keep the initial message to a few sentences and avoid an extensive summary at the beginning. Acknowledge that the patient may be dealing with discomfort or uncertainty.
        """
}

private let spineAIInitialQuestinnaire = try! JSONDecoder().decode(
    Questionnaire.self,
    from: Data("""
    {
      "resourceType": "Questionnaire",
      "id": "lumbar-spine-module",
      "url": "https://spineai.stanford.edu/fhir/Questionnaire/lumbar-spine-triage",
      "version": "1.3",
      "name": "LumbarSpineTriageAndPhenotyping",
      "title": "SpineAI Questionnaire",
      "status": "active",
      "date": "2026-01-23",
      "publisher": "Spine AI Research Team",
      "description": "Triage and phenotyping questionnaire for lumbar spine conditions including axial back pain and radiculopathy.",
      "subjectType": [
        "Patient"
      ],
      "item": [
        {
          "linkId": "Triage",
          "text": "Triage Questions",
          "type": "group",
          "item": [
            {
              "linkId": "T1",
              "text": "Which option best describes your primary symptom?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                    "code": "low-back-only",
                    "display": "Low back pain only"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                    "code": "leg-pain",
                    "display": "Leg pain or numbness"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                    "code": "trouble-walking",
                    "display": "Difficulty walking or standing because of leg symptoms"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                    "code": "mixed",
                    "display": "Both back and leg symptoms"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "T2",
              "text": "How long have these symptoms been present?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/symptom-duration",
                    "code": "lt6w",
                    "display": "Less than 6 weeks"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/symptom-duration",
                    "code": "6w-3m",
                    "display": "6 weeks to 3 months"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/symptom-duration",
                    "code": "3m-12m",
                    "display": "3 to 12 months"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/symptom-duration",
                    "code": "gt12m",
                    "display": "More than 1 year"
                  }
                }
              ],
              "required": true,
              "code": [
                {
                  "system": "http://loinc.org",
                  "code": "38207-7",
                  "display": "Pain duration - Reported"
                }
              ]
            },
            {
              "linkId": "T3",
              "text": "Did your symptoms start following a fall or a significant trauma?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "T4",
              "text": "Have you ever been diagnosed with any form of cancer?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "T5",
              "text": "Have you recently experienced fevers or chills, or have you been diagnosed with a spinal infection?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "T6",
              "text": "Do you currently have any of the following symptoms?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                    "code": "bladder-bowel",
                    "display": "Loss of bladder or bowel control"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                    "code": "leg-weakness",
                    "display": "Severe leg weakness that is getting worse"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                    "code": "perineal-numbness",
                    "display": "Numbness around the groin or inner thighs"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                    "code": "none",
                    "display": "None of the above"
                  },
                  "extension": [
                    {
                      "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive",
                      "valueBoolean": true
                    }
                  ]
                }
              ],
              "repeats": true,
              "required": true
            },
            {
              "linkId": "T7",
              "text": "Have you ever been told you have any of the following conditions?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/structural-context",
                    "code": "stenosis",
                    "display": "Lumbar stenosis"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/structural-context",
                    "code": "scoliosis",
                    "display": "Lumbar scoliosis"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/structural-context",
                    "code": "spondylolisthesis",
                    "display": "Lumbar spondylolisthesis"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/structural-context",
                    "code": "disc",
                    "display": "Lumbar disc herniation"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/structural-context",
                    "code": "none",
                    "display": "None / not sure"
                  },
                  "extension": [
                    {
                      "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive",
                      "valueBoolean": true
                    }
                  ]
                }
              ],
              "repeats": true
            },
            {
              "linkId": "T4a",
              "text": "Do you currently have known metastatic disease involving your spine?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "261665006",
                    "display": "Not sure"
                  }
                }
              ],
              "enableWhen": [
                {
                  "question": "T4",
                  "operator": "=",
                  "answerCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                }
              ],
              "enableBehavior": "all"
            }
          ]
        },
        {
          "linkId": "fracture-pathway",
          "type": "group",
          "text": "Lumbar Fracture Pathway",
          "enableWhen": [
            {
              "question": "T3",
              "operator": "=",
              "answerCoding": {
                "system": "http://snomed.info/sct",
                "code": "373066001",
                "display": "Yes"
              }
            }
          ],
          "enableBehavior": "all",
          "item": [
            {
              "linkId": "fracture-display",
              "type": "display",
              "text": "Please proceed to the Lumbar Fracture Pathway for urgent management."
            }
          ]
        },
        {
          "linkId": "tumor-pathway",
          "type": "group",
          "text": "Lumbar Tumor Pathway",
          "enableWhen": [
            {
              "question": "T4a",
              "operator": "=",
              "answerCoding": {
                "system": "http://snomed.info/sct",
                "code": "373066001",
                "display": "Yes"
              }
            },
            {
              "question": "T4a",
              "operator": "=",
              "answerCoding": {
                "system": "http://snomed.info/sct",
                "code": "261665006",
                "display": "Not sure"
              }
            }
          ],
          "enableBehavior": "any",
          "item": [
            {
              "linkId": "tumor-display",
              "type": "display",
              "text": "Please proceed to the Lumbar Tumor Pathway for evaluation of possible metastasis."
            }
          ]
        },
        {
          "linkId": "infection-pathway",
          "type": "group",
          "text": "Lumbar Infection Pathway",
          "enableWhen": [
            {
              "question": "T5",
              "operator": "=",
              "answerCoding": {
                "system": "http://snomed.info/sct",
                "code": "373066001",
                "display": "Yes"
              }
            }
          ],
          "enableBehavior": "all",
          "item": [
            {
              "linkId": "infection-display",
              "type": "display",
              "text": "Please proceed to the Lumbar Infection Pathway for evaluation of possible infection."
            }
          ]
        },
        {
          "linkId": "emergency-eval",
          "type": "group",
          "text": "Immediate Emergency Evaluation (Possible Cauda Equina)",
          "enableWhen": [
            {
              "question": "T6",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                "code": "bladder-bowel"
              }
            },
            {
              "question": "T6",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                "code": "leg-weakness"
              }
            },
            {
              "question": "T6",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/neurologic-emergency",
                "code": "perineal-numbness"
              }
            }
          ],
          "enableBehavior": "any",
          "item": [
            {
              "linkId": "emergency-display",
              "type": "display",
              "text": "Immediate evaluation is recommended due to potential cauda equina syndrome."
            }
          ]
        },
        {
          "linkId": "axial-module",
          "text": "Axial Lumbar Back Pain Module",
          "type": "group",
          "enableWhen": [
            {
              "question": "T1",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                "code": "low-back-only"
              }
            },
            {
              "question": "T1",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                "code": "mixed"
              }
            }
          ],
          "enableBehavior": "any",
          "item": [
            {
              "linkId": "A1",
              "text": "Where do you feel your back pain?",
              "type": "choice",
              "repeats": true,
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-pain-location",
                    "code": "central",
                    "display": "Central low back"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-pain-location",
                    "code": "right",
                    "display": "More on the right side"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-pain-location",
                    "code": "left",
                    "display": "More on the left side"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-pain-location",
                    "code": "both",
                    "display": "Both sides equally"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-pain-location",
                    "code": "buttock",
                    "display": "Low back and upper buttock"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "A2",
              "text": "Which activities make your back pain worse?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-aggravating-activity",
                    "code": "sitting",
                    "display": "Sitting"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-aggravating-activity",
                    "code": "standing",
                    "display": "Standing"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-aggravating-activity",
                    "code": "walking",
                    "display": "Walking"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-aggravating-activity",
                    "code": "bend-forward",
                    "display": "Bending forward"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-aggravating-activity",
                    "code": "bend-backward",
                    "display": "Bending backward"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-aggravating-activity",
                    "code": "twisting",
                    "display": "Twisting or rotating"
                  }
                }
              ],
              "repeats": true
            },
            {
              "linkId": "A3",
              "text": "Does lying down improve your pain?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "A4",
              "text": "When you bend forward, does your pain improve, stay the same, or worsen?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-forward-bending",
                    "code": "improves",
                    "display": "Improves"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-forward-bending",
                    "code": "same",
                    "display": "Same"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-forward-bending",
                    "code": "worsens",
                    "display": "Worsens"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "A5",
              "text": "When you bend backward, does your pain improve, stay the same, or worsen?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-backward-bending",
                    "code": "improves",
                    "display": "Improves"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-backward-bending",
                    "code": "same",
                    "display": "Same"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-backward-bending",
                    "code": "worsens",
                    "display": "Worsens"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "A6",
              "text": "Is your pain generally worse when you are sitting, standing, or about the same?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-posture-worse",
                    "code": "sitting",
                    "display": "Sitting"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-posture-worse",
                    "code": "standing",
                    "display": "Standing"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-posture-worse",
                    "code": "same",
                    "display": "About the same"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "A7",
              "text": "If sitting makes your pain worse, is it pain that builds while you are sitting or does it become severe when standing after sitting?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-sitting-clarification",
                    "code": "builds",
                    "display": "Pain that builds while sitting"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-sitting-clarification",
                    "code": "standing-after",
                    "display": "Pain that becomes severe when standing after sitting"
                  }
                }
              ],
              "enableWhen": [
                {
                  "question": "A6",
                  "operator": "=",
                  "answerCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-posture-worse",
                    "code": "sitting"
                  }
                }
              ],
              "enableBehavior": "any"
            },
            {
              "linkId": "A8",
              "text": "Have you ever been told you have scoliosis (a curvature of the spine)?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "261665006",
                    "display": "Not sure"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "A9",
              "text": "If you have scoliosis, is your back pain worse on one side of your back?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "enableWhen": [
                {
                  "question": "A8",
                  "operator": "=",
                  "answerCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                }
              ],
              "enableBehavior": "any"
            },
            {
              "linkId": "A10",
              "text": "Which side has more severe back pain?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-worse-side",
                    "code": "right",
                    "display": "Right"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/axial-worse-side",
                    "code": "left",
                    "display": "Left"
                  }
                }
              ],
              "enableWhen": [
                {
                  "question": "A9",
                  "operator": "=",
                  "answerCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                }
              ],
              "enableBehavior": "any"
            }
          ]
        },
        {
          "linkId": "radic-module",
          "text": "Lumbar Radiculopathy Module",
          "type": "group",
          "enableWhen": [
            {
              "question": "T1",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                "code": "leg-pain"
              }
            },
            {
              "question": "T1",
              "operator": "=",
              "answerCoding": {
                "system": "https://spineai.stanford.edu/CodeSystem/primary-symptom",
                "code": "mixed"
              }
            }
          ],
          "enableBehavior": "any",
          "item": [
            {
              "linkId": "R2-left",
              "text": "In your left leg, where do you feel pain?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "none",
                    "display": "No pain in this leg"
                  },
                  "extension": [
                    {
                      "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive",
                      "valueBoolean": true
                    }
                  ]
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "buttock",
                    "display": "Buttock"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "front-thigh",
                    "display": "Front of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "back-thigh",
                    "display": "Back of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "medial-shin",
                    "display": "Front/inside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "lateral-shin",
                    "display": "Outside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "top-foot",
                    "display": "Top of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "bottom-foot",
                    "display": "Bottom of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "big-toe",
                    "display": "Big toe"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "small-toe",
                    "display": "Small toe"
                  }
                }
              ],
              "repeats": true
            },
            {
              "linkId": "R2-right",
              "text": "In your right leg, where do you feel pain?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "none",
                    "display": "No pain in this leg"
                  },
                  "extension": [
                    {
                      "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive",
                      "valueBoolean": true
                    }
                  ]
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "buttock",
                    "display": "Buttock"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "front-thigh",
                    "display": "Front of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "back-thigh",
                    "display": "Back of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "medial-shin",
                    "display": "Front/inside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "lateral-shin",
                    "display": "Outside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "top-foot",
                    "display": "Top of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "bottom-foot",
                    "display": "Bottom of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "big-toe",
                    "display": "Big toe"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-pain-loc",
                    "code": "small-toe",
                    "display": "Small toe"
                  }
                }
              ],
              "repeats": true
            },
            {
              "linkId": "R3",
              "text": "Do you experience numbness or tingling?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness",
                    "code": "no",
                    "display": "No"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness",
                    "code": "yes-same",
                    "display": "Yes - same area as pain"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness",
                    "code": "yes-diff",
                    "display": "Yes - different area"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R3-left",
              "text": "In your left leg, where do you feel numbness or tingling?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "buttock",
                    "display": "Buttock"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "front-thigh",
                    "display": "Front of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "back-thigh",
                    "display": "Back of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "medial-shin",
                    "display": "Front/inside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "lateral-shin",
                    "display": "Outside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "top-foot",
                    "display": "Top of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "bottom-foot",
                    "display": "Bottom of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "big-toe",
                    "display": "Big toe"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "small-toe",
                    "display": "Small toe"
                  }
                }
              ],
              "repeats": true,
              "enableWhen": [
                {
                  "question": "R3",
                  "operator": "=",
                  "answerCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness",
                    "code": "yes-diff"
                  }
                }
              ],
              "enableBehavior": "any"
            },
            {
              "linkId": "R3-right",
              "text": "In your right leg, where do you feel numbness or tingling?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "buttock",
                    "display": "Buttock"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "front-thigh",
                    "display": "Front of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "back-thigh",
                    "display": "Back of thigh"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "medial-shin",
                    "display": "Front/inside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "lateral-shin",
                    "display": "Outside of shin"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "top-foot",
                    "display": "Top of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "bottom-foot",
                    "display": "Bottom of foot"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "big-toe",
                    "display": "Big toe"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness-loc",
                    "code": "small-toe",
                    "display": "Small toe"
                  }
                }
              ],
              "repeats": true,
              "enableWhen": [
                {
                  "question": "R3",
                  "operator": "=",
                  "answerCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-numbness",
                    "code": "yes-diff"
                  }
                }
              ],
              "enableBehavior": "any"
            },
            {
              "linkId": "R4",
              "text": "Does coughing, sneezing, or straining make your leg pain worse?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "261665006",
                    "display": "Not sure"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R5",
              "text": "Have you noticed any weakness in your leg?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-weakness",
                    "code": "none",
                    "display": "No weakness"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-weakness",
                    "code": "mild",
                    "display": "Mild"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-weakness",
                    "code": "moderate",
                    "display": "Moderate"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-weakness",
                    "code": "severe",
                    "display": "Severe - I cannot lift my foot up or push off with my foot"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R6",
              "text": "Have you experienced any of the following motor difficulties?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-functional-motor",
                    "code": "heel-walking",
                    "display": "Trouble walking on heels"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-functional-motor",
                    "code": "toe-walking",
                    "display": "Trouble walking on toes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-functional-motor",
                    "code": "knee-gives",
                    "display": "Knee gives way"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-functional-motor",
                    "code": "hip-weak",
                    "display": "Hip feels weak lifting the leg"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-functional-motor",
                    "code": "none",
                    "display": "None"
                  },
                  "extension": [
                    {
                      "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive",
                      "valueBoolean": true
                    }
                  ]
                }
              ],
              "repeats": true
            },
            {
              "linkId": "R7",
              "text": "How did your leg pain start?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-onset",
                    "code": "sudden",
                    "display": "Suddenly"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-onset",
                    "code": "gradual-weeks",
                    "display": "Gradually over weeks"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-onset",
                    "code": "gradual-months",
                    "display": "Gradually over months"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R8",
              "text": "How long have you had leg symptoms?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-duration",
                    "code": "lt6w",
                    "display": "< 6 weeks"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-duration",
                    "code": "6w-3m",
                    "display": "6 weeks - 3 months"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-duration",
                    "code": "3m-12m",
                    "display": "3 - 12 months"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-duration",
                    "code": "gt12m",
                    "display": "> 12 months"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R9",
              "text": "Do your symptoms get worse when you stand or walk and improve when you sit?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R10",
              "text": "Does leaning forward while walking, such as in a shopping-cart position, relieve your symptoms?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373066001",
                    "display": "Yes"
                  }
                },
                {
                  "valueCoding": {
                    "system": "http://snomed.info/sct",
                    "code": "373067005",
                    "display": "No"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R11",
              "text": "How much does pain limit your walking?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/walking-limitation",
                    "code": "no-limit",
                    "display": "Pain does not prevent me from walking any distance"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/walking-limitation",
                    "code": "one-mile",
                    "display": "Pain prevents me from walking more than 1 mile"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/walking-limitation",
                    "code": "half-mile",
                    "display": "Pain prevents me from walking more than 1/2 mile"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/walking-limitation",
                    "code": "hundred-yards",
                    "display": "Pain prevents me from walking more than 100 yards"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/walking-limitation",
                    "code": "stick",
                    "display": "I can only walk using a stick or crutches"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/walking-limitation",
                    "code": "bed",
                    "display": "I am in bed most of the time"
                  }
                }
              ],
              "required": true
            },
            {
              "linkId": "R12",
              "text": "Have you ever been told you have any of these conditions?",
              "type": "choice",
              "answerOption": [
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-structural-history",
                    "code": "stenosis",
                    "display": "Lumbar stenosis"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-structural-history",
                    "code": "spondylolisthesis",
                    "display": "Spondylolisthesis"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-structural-history",
                    "code": "scoliosis",
                    "display": "Lumbar scoliosis"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-structural-history",
                    "code": "disc",
                    "display": "Disc herniation"
                  }
                },
                {
                  "valueCoding": {
                    "system": "https://spineai.stanford.edu/CodeSystem/radic-structural-history",
                    "code": "none",
                    "display": "None / not sure"
                  },
                  "extension": [
                    {
                      "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-optionExclusive",
                      "valueBoolean": true
                    }
                  ]
                }
              ],
              "repeats": true
            }
          ]
        }
      ]
    }
    """.utf8)
)
