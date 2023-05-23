//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import Spezi
import SpeziHealthKit
import SpeziOpenAI
import SwiftUI


class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: FHIR()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            OpenAIComponent()
            FHIRResourceInterpreter()
            FHIRResourceSummary()
        }
    }
    
    
    private var healthKit: HealthKit<FHIR> {
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
        } adapter: {
            HealthKitToFHIRAdapter()
        }
    }
}
