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
    let region: String

    /// Auth emulator address in `host:port` format (e.g. `"localhost:9099"`).
    /// When set, auth requests are routed to the emulator instead of production.
    let authEmulatorAddress: String?

    /// Functions emulator address in `host:port` format (e.g. `"localhost:5001"`).
    /// When set, function calls are routed to the emulator instead of production.
    let functionsEmulatorAddress: String?

    init(
        apiKey: String,
        projectID: String,
        region: String? = nil,
        authEmulatorAddress: String? = nil,
        functionsEmulatorAddress: String? = nil
    ) {
        self.apiKey = apiKey
        self.projectID = projectID
        self.region = region ?? "us-central1"
        self.authEmulatorAddress = authEmulatorAddress
        self.functionsEmulatorAddress = functionsEmulatorAddress
    }

    init(contentsOfFile path: String, region: String? = nil) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let apiKey = plist["API_KEY"] as? String,
              let projectID = plist["PROJECT_ID"] as? String else {
            throw FirebaseConfigError("Could not parse Firebase configuration at '\(path)'")
        }
        self.init(apiKey: apiKey, projectID: projectID, region: region)
    }
}
