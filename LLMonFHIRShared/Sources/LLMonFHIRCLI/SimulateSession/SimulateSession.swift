//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable attributes

import ArgumentParser
import Foundation
import LLMonFHIRShared
import LLMonFHIRStudyDefinitions
@_spi(APISupport) import Spezi
import SpeziChat
import SpeziFHIR
import SpeziHealthKit
import SpeziLLM
import SpeziLLMOpenAI


struct SimulateSession: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "simulate-session",
        abstract: "Runs a simulated session, using a synthetic patient's context and pre-defined user prompts.",
    )
    
    @Argument(help: "Input file")
    var inputUrl: URL
    
    @Argument(help: "Output directory")
    var outputUrl: URL
    
    @MainActor
    func run() async throws {
        let configs = try JSONDecoder().decode([SimulatedSessionConfig].self, from: Data(contentsOf: inputUrl))
        let reports = try await withThrowingTaskGroup(of: StudyReport.self, returning: [StudyReport].self) { taskGroup in
            for config in configs {
                for runIdx in 0..<config.numberOfRuns {
                    taskGroup.addTask {
                        let simulator = await SessionSimulator(config: config)
                        return try await simulator.run()
                    }
                }
            }
            var reports: [StudyReport] = []
            while let report = try await taskGroup.next() {
                reports.append(report)
            }
            return reports
        }
        
//        if fileManager.itemExists(at: outputUrl) {
//            try fileManager.removeItem(at: outputUrl)
//        }
        try FileManager.default.createDirectory(at: outputUrl, withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        for report in reports {
            let dstUrl = outputUrl.appendingPathComponent(UUID().uuidString, conformingTo: .json)
            let reportData = try encoder.encode(report)
            print("WILL WRITE TO \(dstUrl)")
            try reportData.write(to: dstUrl)
        }
    }
}
