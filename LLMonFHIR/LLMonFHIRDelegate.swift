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
                LLMOpenAIPlatform(
                    configuration: .init(
                        authToken: .keychain(tag: .openAIKey, username: LLMonFHIRConstants.credentialsUsername),
                        concurrentStreams: 100
                    )
                )
            }
            FHIRInterpretationModule()
            AccessGuardModule {
                FixedAccessGuard(
                    .userStudyIdentifier,
                    code: "0218",
                    codeOptions: .fourDigitNumeric,
                    timeout: .hours(1)
                )
            }
        }
    }
    
    
    private var healthKit: HealthKit {
        HealthKit {
            RequestReadAccess(other: LLMonFHIRStandard.recordTypes)
        }
    }
}
