//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi
import SpeziAccessGuard
import SpeziFHIR
import SpeziHealthKit
import SpeziLLM
import SpeziLLMLocal
import SpeziLLMOpenAI
import SwiftUI


class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(concurrentStreams: 100))
            }
            FHIRInterpretationModule()
            AccessGuardModule([
                .fixed(
                    identifier: .userStudyIndentifier,
                    code: "0218",
                    codeOptions: .fourDigitNumeric,
                    timeout: 60 * 60
                )
            ])
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
