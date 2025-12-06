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
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI
import SwiftUI


class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            if HKHealthStore.isHealthDataAvailable() {
                healthKit
            }
//            let userStudyCodes = UserStudyCodes()
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
            AccessGuards {
                CodeAccessGuard(
                    .userStudy,
                    timeout: .hours(1),
                    message: "Enter one of 10 codes to start the user study",
                    format: .numeric(4)
                ) { code in
                    //await userStudyCodes.validate(code)
                    .valid
                }
            }
//            userStudyCodes
        }
    }
    
    
    private var healthKit: HealthKit {
        HealthKit {
            RequestReadAccess(other: LLMonFHIRStandard.recordTypes)
        }
    }
}
