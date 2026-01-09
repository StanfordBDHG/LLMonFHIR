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
            let fhirInterpretationModule = FHIRInterpretationModule()
            HealthKit {
                RequestReadAccess(other: LLMonFHIRStandard.recordTypes)
                for type in LLMonFHIRStandard.recordTypes {
                    CollectSamples(type, start: .manual, continueInBackground: false, timeRange: .newSamples)
                }
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
            AccessGuards {
                CodeAccessGuard(.userStudySettings, message: "Enter Code to Access Settings", format: .numeric(4)) { @MainActor code in
                    if let expected = fhirInterpretationModule.currentStudy?.settingsUnlockCode {
                        code == expected ? .valid : .invalid
                    } else {
                        .valid
                    }
                }
            }
        }
    }
}
