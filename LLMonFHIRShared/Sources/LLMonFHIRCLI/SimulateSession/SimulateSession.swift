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
//@_spi(APISupport) import Spezi
//import SpeziLLM
//import SpeziLLMOpenAI


struct SimulateSession: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "simulate-session",
        abstract: "Runs a simulated session, using a synthetic patient's context and pre-defined user prompts.",
    )
    
    @Argument(help: "Input file")
    var inputUrl: URL
    
    @Argument(help: "Output file")
    var outputUrl: URL
    
    func run() async throws {
        let config = try JSONDecoder().decode(SimulatedSessionConfig.self, from: Data(contentsOf: inputUrl))
        print(config)
        
//        let spezi = Spezi(from: speziConfig(for: config))
//        
//        // TODO is this necessary?
//        withExtendedLifetime(spezi) { _ = $0 }
    }
}


//extension SimulateSession {
//    private func speziConfig(for commandConfig: SimulatedSessionConfig) -> Configuration {
//        Configuration {
//            LLMRunner {
//                LLMOpenAIPlatform(configuration: .init(
//                    authToken: .constant(commandConfig.openAIKey),
//                    concurrentStreams: 100,
//                    retryPolicy: .attempts(3),  // Automatically perform up to 3 retries on retryable OpenAI API status codes
////                    middlewares: [OpenAIRequestInterceptor(fhirInterpretationModule)]
//                ))
//            }
//        }
//    }
//}
