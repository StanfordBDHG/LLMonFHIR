//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable attributes all

import ArgumentParser
import Foundation
import LLMonFHIRShared
import LLMonFHIRStudyDefinitions
@_spi(APISupport) import Spezi
import SpeziChat
import SpeziLLM
import SpeziLLMOpenAI
import SpeziFHIR


struct SimulateSession: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "simulate-session",
        abstract: "Runs a simulated session, using a synthetic patient's context and pre-defined user prompts.",
    )
    
    @Argument(help: "Input file")
    var inputUrl: URL
    
    @Argument(help: "Output file")
    var outputUrl: URL
    
    @MainActor
    func run() async throws {
        let config = try JSONDecoder().decode(SimulatedSessionConfig.self, from: Data(contentsOf: inputUrl))
        print(config)
        
        let spezi = Spezi(from: speziConfig(for: config))
        
        let interpreter = FHIRMultipleResourceInterpreter(
            localStorage: spezi[LocalStorage.self]!,
            llmRunner: spezi[LLMRunner.self]!,
            llmSchema: <#T##any LLMSchema#>,
            fhirStore: <#T##FHIRStore#>
        )
        guard let interpreter = spezi.module(FHIRMultipleResourceInterpreter.self) else {
            fatalError()
        }
        
        // TODO is this necessary?
        withExtendedLifetime(spezi) { _ = $0 }
    }
    
    
    @MainActor
    private func _run(_ config: SimulatedSessionConfig, using interpreter: FHIRMultipleResourceInterpreter) async throws {
        var chat: Chat {
            get {
                interpreter.llmSession.context.chat ?? []
            }
            set {
                interpreter.llmSession.context.chat = newValue
            }
        }
        for question in config.userQuestions {
            
        }
    }
}


extension SimulateSession {
    @MainActor
    private func speziConfig(for commandConfig: SimulatedSessionConfig) -> Configuration {
        Configuration {
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(
                    authToken: .constant(commandConfig.openAIKey),
                    concurrentStreams: 100,
                    retryPolicy: .attempts(3),  // Automatically perform up to 3 retries on retryable OpenAI API status codes
//                    middlewares: [OpenAIRequestInterceptor(fhirInterpretationModule)]
                ))
            }
        }
    }
}


extension Spezi {
    subscript<M: Module>(_ moduleType: M.Type) -> M? {
        module(moduleType)
    }
}




//@Observable
//final class FHIRInterpretationModule: Module, @unchecked Sendable {
//    @ObservationIgnored @MainActor @Dependency(LLMRunner.self) private var llmRunner
//    @ObservationIgnored @MainActor @Dependency(FHIRStore.self) private var fhirStore
//    
//    @ObservationIgnored @MainActor private var resourceSummary: FHIRResourceSummary
//    @ObservationIgnored @MainActor private var resourceInterpreter: FHIRResourceInterpreter
//    @ObservationIgnored @MainActor private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
//}
