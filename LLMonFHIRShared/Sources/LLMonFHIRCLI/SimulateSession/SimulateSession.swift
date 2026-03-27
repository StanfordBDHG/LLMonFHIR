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
        let configs = try JSONDecoder().decode(
            [SimulatedSessionConfig].self,
            from: Data(contentsOf: inputUrl),
            configuration: .init(configFileUrl: inputUrl)
        )

        let outputUrl = outputUrl.appending(
            path: Date.now.formatted(Date.ISO8601FormatStyle.suitableForFilenames),
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: outputUrl, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]

        var savedCount = 0
        var failedSessionCount = 0
            for (configIdx, config) in configs.enumerated() where config.service == .firebaseEmulator {
                for runIdx in 0..<config.numberOfRuns {
                        let simulator = SessionSimulator(config: config, runIdx: runIdx)
                        let sessionDesc = simulator.sessionDesc
                        do {
                            let report = try await simulator.run()
                            let sanitized = (config.name ?? "session")
                                .components(separatedBy: CharacterSet(charactersIn: "/\\"))
                                .joined()
                                .replacingOccurrences(of: "..", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            let name = String(format: "%02d", configIdx) + "-" + (sanitized.isEmpty ? "session" : sanitized)
                            let dstUrl = outputUrl.appendingPathComponent("\(name)-\(runIdx + 1)", conformingTo: .json)
                            let reportData = try encoder.encode(report)
                            try reportData.write(to: dstUrl)
                    savedCount += 1
                        } catch {
                            print("\(sessionDesc) failed: \(error.localizedDescription) \(error)")
                    failedSessionCount += 1
                        }
                }
            }

        if failedSessionCount > 0 {
            throw ExitCode.failure
        }
    }
}


extension Date.ISO8601FormatStyle {
    /// An ISO-8601 format style suitable for use in filenames.
    static let suitableForFilenames = Self(
        dateSeparator: .dash,
        dateTimeSeparator: .standard,
        timeSeparator: .omitted,
        timeZoneSeparator: .omitted,
        includingFractionalSeconds: true
    )
}
