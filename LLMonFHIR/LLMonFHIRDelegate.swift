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
import SpeziLLMLocal
import SpeziLLMOpenAI
import SwiftUI


class LLMonFHIRDelegate: SpeziAppDelegate {
    @AppStorage(StorageKeys.llmSourceSummarizationInterpretation) private var llmSourceSummarizationInterpretation =
        StorageKeys.Defaults.llmSourceSummarizationInterpretation
    @AppStorage(StorageKeys.llmOpenAiMultipleInterpretation) private var llmOpenAiMultipleInterpretation =
        StorageKeys.Defaults.llmOpenAiMultipleInterpretation
    
    
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(concurrentStreams: 20))
                LLMLocalPlatform()
                LLMFogPlatform(configuration: .init(caCertificate: nil, concurrentStreams: 1, timeout: 120))
            }
            FHIRInterpretationModule(
                summaryLLMSchema: llmSourceSummarizationInterpretation.llmSchema,
                interpretationLLMSchema: llmSourceSummarizationInterpretation.llmSchema,
                multipleResourceInterpretationOpenAIModel: llmOpenAiMultipleInterpretation
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
