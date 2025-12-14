//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziAccessGuard
import SpeziHealthKit
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI


final class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            HealthKit {
                RequestReadAccess(other: LLMonFHIRStandard.recordTypes)
                for type in LLMonFHIRStandard.recordTypes {
                    CollectSamples(type, start: .manual, continueInBackground: false, timeRange: .newSamples)
                }
            }
            AccessGuards {
                CodeAccessGuard(.userStudy, fixed: "1234")
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
        }
    }
}
