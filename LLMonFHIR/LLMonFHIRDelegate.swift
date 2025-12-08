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
import SpeziHealthKit
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI
import SwiftUI


final class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
            LLMRunner {
                LLMOpenAIPlatform(
                    configuration: .init(
                        authToken: .keychain(tag: .openAIKey, username: "LLMonFHIR_OpenAI_Token"),
                        concurrentStreams: 100,
                        retryPolicy: .attempts(3)  // Automatically perform up to 3 retries on retryable OpenAI API status codes
                    )
                )
                LLMFogPlatform(configuration: .init(host: "spezillmfog.local", connectionType: .http, authToken: .none))
                LLMLocalPlatform()
            }
            FHIRInterpretationModule()
            CurrentStudyManager()
        }
    }
    
    
    private var healthKit: HealthKit {
        HealthKit {
            RequestReadAccess(other: LLMonFHIRStandard.recordTypes)
            for type in LLMonFHIRStandard.recordTypes {
                CollectSample(type, start: .manual, continueInBackground: false, timeRange: .newSamples)
            }
        }
    }
}
