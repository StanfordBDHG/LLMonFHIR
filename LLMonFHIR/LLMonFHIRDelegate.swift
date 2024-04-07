//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi
import SpeziFHIR
import SpeziFHIRLLM
import SpeziHealthKit
import SpeziLLM
import SpeziLLMFog
import SpeziLLMOpenAI
import SwiftUI


class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(concurrentStreams: 20))
                LLMFogPlatform(configuration: .i)
            }
            FHIRInterpretationModule(
                summaryLLMSchema:
                    LLMOpenAISchema(
                        parameters: .init(
                            modelType: .gpt4_1106_preview,
                            systemPrompts: []   // No system prompt as this will be determined later by the resource interpreter
                        )
                    ),
                interpretationLLMSchema: LLMOpenAISchema(
                    parameters: .init(
                        modelType: .gpt4_1106_preview,
                        systemPrompts: []   // No system prompt as this will be determined later by the resource interpreter
                    )
                ),
                multipleResourceInterpretationOpenAIModel: .gpt4_1106_preview
            )
        }
    }
    
    
    private var healthKit: HealthKit {
        HealthKit {
            CollectSamples(
                [
                    HKClinicalType(.allergyRecord),
                    HKClinicalType(.clinicalNoteRecord),
                    HKClinicalType(.conditionRecord),
                    HKClinicalType(.coverageRecord),
                    HKClinicalType(.immunizationRecord),
                    HKClinicalType(.labResultRecord),
                    HKClinicalType(.medicationRecord),
                    HKClinicalType(.procedureRecord),
                    HKClinicalType(.vitalSignRecord)
                ],
                predicate: HKQuery.predicateForSamples(
                    withStart: Date.distantPast,
                    end: nil,
                    options: .strictEndDate
                ),
                deliverySetting: .anchorQuery(saveAnchor: false)
            )
        }
    }
}
