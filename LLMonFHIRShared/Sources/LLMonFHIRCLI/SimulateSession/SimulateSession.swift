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
        abstract:
            "Runs a simulated session, using a synthetic patient's context and pre-defined user prompts.",
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

        // Fail early if Firebase credentials are required but not provided
        if configs.contains(where: { $0.service == .firebase }),
           ProcessInfo.processInfo.environment["GOOGLE_CREDENTIALS_PLIST"]?.isEmpty ?? true {
            throw ValidationError(
                "GOOGLE_CREDENTIALS_PLIST environment variable is required when using the 'Firebase' service."
            )
        }
        let outputUrl = outputUrl.appending(
            path: Date.now.formatted(Date.ISO8601FormatStyle.suitableForFilenames),
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: outputUrl, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]

        var savedCount = 0
        var failedSessionCount = 0
        await withTaskGroup(of: Bool.self) { taskGroup in
            for (configIdx, config) in configs.enumerated() {
                for runIdx in 0..<config.numberOfRuns {
                    taskGroup.addTask {
                        let simulator = await SessionSimulator(config: config, runIdx: runIdx)
                        let sessionDesc = simulator.sessionDesc
                        print("Starting \(sessionDesc)")
                        do {
                            let report = try await simulator.run()
                            let name = config.name ?? "session\(configIdx)"
                            let dstUrl = outputUrl.appendingPathComponent("\(name)-\(runIdx + 1)", conformingTo: .json)
                            let reportData = try encoder.encode(report)
                            try reportData.write(to: dstUrl)
                            print("Ended \(sessionDesc) → \(dstUrl.lastPathComponent)")
                            return true
                        } catch {
                            print("\(sessionDesc) failed: \(error.localizedDescription) \(error)")
                            return false
                        }
                    }
                }
            }
            for await success in taskGroup {
                if success {
                    savedCount += 1
                } else {
                    failedSessionCount += 1
                }
            }
        }

        print("\(savedCount) session(s) saved, \(failedSessionCount) failed.")
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
