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
import SpeziFHIRMockDataStorageProvider
import SpeziHealthKit
import SpeziHealthKitToFHIRAdapter
import SpeziQuestionnaire
import SpeziScheduler
import SwiftUI


class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: FHIR()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            QuestionnaireDataSource()
            MockDataStorageProvider()
            LLMonFHIRScheduler()
        }
    }
    
    
    private var healthKit: HealthKit<FHIR> {
        HealthKit {
            CollectSample(
                HKQuantityType(.stepCount),
                deliverySetting: .anchorQuery(.afterAuthorizationAndApplicationWillLaunch)
            )
        } adapter: {
            HealthKitToFHIRAdapter()
        }
    }
}
