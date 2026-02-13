//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable type_contents_order

import FirebaseCore
import GeneratedOpenAIClient // periphery:ignore - false positive
import LLMonFHIRShared
@_spi(APISupport) import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirebaseAccountStorage
import SpeziFirebaseConfiguration
import SpeziFirebaseStorage
import SpeziFoundation
import SpeziHealthKit
import SpeziKeychainStorage
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI


final class LLMonFHIRDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: LLMonFHIRStandard()) {
            if !FeatureFlags.disableFirebase, let config = AppConfigFile.current().firebaseConfig {
                firebaseModules(using: config)
            }
            let openAIInterceptor = OpenAIRequestInterceptor()
            openAIInterceptor
            let fhirInterpretationModule = FHIRInterpretationModule()
            fhirInterpretationModule
            HealthKit {
                if HKHealthStore().supportsHealthRecords() {
                    RequestReadAccess(other: LLMonFHIRStandard.recordTypes)
                    for type in LLMonFHIRStandard.recordTypes {
                        CollectSamples(type, start: .manual, continueInBackground: false, timeRange: .newSamples)
                    }
                }
            }
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(
                    authToken: self.openAITokenConfig,
                    concurrentStreams: 100,
                    retryPolicy: .attempts(3),  // Automatically perform up to 3 retries on retryable OpenAI API status codes
                    middlewares: [openAIInterceptor]
                ))
                LLMFogPlatform(configuration: .init(host: "spezillmfog.local", connectionType: .http, authToken: .none))
                LLMLocalPlatform()
            }
        }
    }
    
    @ModuleBuilder
    private func firebaseModules(using config: AppConfigFile.FirebaseConfigDictionary) -> ModuleCollection {
        ConfigureFirebaseApp(options: FirebaseOptions(config)!) // swiftlint:disable:this force_unwrapping
        AccountConfiguration(
            service: FirebaseAccountService(
                providers: [],
                emulatorSettings: accountEmulatorSettings
            ),
            configuration: []
        )
        if FeatureFlags.useFirebaseEmulator {
            FirebaseStorageConfiguration(emulatorSettings: (host: "localhost", port: 9199))
            FirebaseFunctions(emulatorHost: "localhost", port: 5001)
        } else {
            FirebaseStorageConfiguration()
            FirebaseFunctions()
        }
        FirebaseUpload()
    }
    
    private var accountEmulatorSettings: (host: String, port: Int)? {
        if FeatureFlags.useFirebaseEmulator {
            (host: "localhost", port: 9099)
        } else {
            nil
        }
    }
    
    nonisolated private var openAITokenConfig: RemoteLLMInferenceAuthToken {
        switch LLMonFHIR.mode {
        case .standalone, .test:
            .keychain(tag: .openAIKey, username: "LLMonFHIR_OpenAI_Token")
        case .study:
            .closure { @MainActor in
                Self.spezi?.module(FHIRInterpretationModule.self)?.currentStudy?.config.openAIAPIKey
            }
        }
    }
}


extension FirebaseOptions {
    convenience init?(_ config: AppConfigFile.FirebaseConfigDictionary) {
        let fileManager = FileManager.default
        let tmpUrl = URL.temporaryDirectory.appendingPathComponent("FirebaseConfig", conformingTo: .propertyList)
        try? fileManager.removeItem(at: tmpUrl)
        do {
            try config.asNSDictionary().write(to: tmpUrl)
        } catch {
            return nil
        }
        defer {
            try? fileManager.removeItem(at: tmpUrl)
        }
        self.init(contentsOfFile: tmpUrl.absoluteURL.path(percentEncoded: false))
    }
}
