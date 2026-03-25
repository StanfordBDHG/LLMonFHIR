//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct FirebaseConfigError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

struct FirebaseConfig {
    let apiKey: String
    let projectID: String

    /// Auth emulator address in `host:port` format (e.g. `"localhost:9099"`).
    /// When set, auth requests are routed to the emulator instead of production.
    let authEmulatorAddress: String?

    /// Functions emulator address in `host:port` format (e.g. `"localhost:5001"`).
    /// When set, function calls are routed to the emulator instead of production.
    let functionsEmulatorAddress: String?

    init(
        apiKey: String,
        projectID: String,
        authEmulatorAddress: String? = nil,
        functionsEmulatorAddress: String? = nil
    ) {
        self.apiKey = apiKey
        self.projectID = projectID
        self.authEmulatorAddress = authEmulatorAddress
        self.functionsEmulatorAddress = functionsEmulatorAddress
    }

    init(contentsOfFile path: String) throws {
        guard let plist = Dictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String,
              let projectID = plist["PROJECT_ID"] as? String else {
            throw FirebaseConfigError("Could not parse Firebase configuration at '\(path)'")
        }
        self.init(apiKey: apiKey, projectID: projectID)
    }
}
