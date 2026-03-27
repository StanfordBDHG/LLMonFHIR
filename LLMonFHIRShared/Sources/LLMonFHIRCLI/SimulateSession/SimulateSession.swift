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
        discussion: #"""
            Each entry in the JSON config file defines one simulation scenario. Supported fields:

              numberOfRuns        (required) Number of times to repeat this scenario.
              studyId             (required) Study identifier.
              bundleName          (required) Embedded patient name, or path to a FHIR bundle JSON
                                             file (resolved relative to the config file).
              model               (required) OpenAI model name (e.g. "gpt-4o").
              temperature         (required) Sampling temperature.
              userQuestions       (required) List of questions the simulated patient asks.
              service             (optional) Backend: "OpenAI", "Firebase", or "Firebase-Emulator".
                                             Inferred from the environment when omitted (see below).
              name                (optional) Human-readable label used as the output filename prefix.
              customSystemPrompt  (optional) Custom system prompt text.

            API credentials are never stored in the config file. They are read from the environment:

              OPENAI_API_KEY              Required for the "OpenAI" service.
              GOOGLE_CREDENTIALS_PLIST    Path to GoogleService-Info.plist; required for "Firebase",
                                          optional for "Firebase-Emulator" (uses placeholder
                                          credentials when unset).

            Service inference (when "service" is omitted from a config entry):
              1. OPENAI_API_KEY is set and non-empty        → "OpenAI"
              2. GOOGLE_CREDENTIALS_PLIST is set and valid  → "Firebase"
              3. Neither is available                       → "Firebase-Emulator"

            Optional Firebase environment variables:

              FIREBASE_REGION                  Firebase region (default: us-central1).
              FIREBASE_AUTH_EMULATOR_HOST      Auth emulator address host:port
                                               (default: localhost:9099; emulator mode only).
              FIREBASE_FUNCTIONS_EMULATOR_HOST Functions emulator address host:port
                                               (default: localhost:5001; emulator mode only).

            Output reports are written to a timestamped subdirectory of the output directory,
            named <index>-<name>-<run>.json (e.g. 00-my-scenario-1.json).
            """#
    )

    @Argument(help: "Path to the JSON config file describing the sessions to simulate.")
    var inputUrl: URL

    @Argument(help: "Directory where output report files will be written.")
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
            for (configIdx, config) in configs.enumerated() {
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
