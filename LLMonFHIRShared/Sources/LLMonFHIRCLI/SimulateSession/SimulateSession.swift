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
        var failedSessionCount = 0
        let reports = await withTaskGroup(
            of: StudyReport?.self, returning: [StudyReport].self
        ) { taskGroup in
            for config in configs {
                for runIdx in 0..<config.numberOfRuns {
                    taskGroup.addTask {
                        let simulator = await SessionSimulator(config: config, runIdx: runIdx)
                        let sessionDesc = simulator.sessionDesc
                        print("Starting \(sessionDesc)")
                        do {
                            let result = try await simulator.run()
                            print("Ended \(sessionDesc)")
                            return result
                        } catch {
                            print("\(sessionDesc) failed: \(error.localizedDescription) \(error)")
                            return nil
                        }
                    }
                }
            }
            var reports: [StudyReport] = []
            for await report in taskGroup {
                if let report {
                    reports.append(report)
                } else {
                    failedSessionCount += 1
                }
            }
            return reports
        }

        let outputUrl = outputUrl.appending(
            path: Date.now.formatted(Date.ISO8601FormatStyle.suitableForFilenames),
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: outputUrl, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        for report in reports {
            let dstUrl = outputUrl.appendingPathComponent(UUID().uuidString, conformingTo: .json)
            let reportData = try encoder.encode(report)
            print("Writing report file to \(dstUrl.path)")
            try reportData.write(to: dstUrl)
        }

        print("\(reports.count) session(s) saved, \(failedSessionCount) failed.")
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
