//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


struct UserStudyPlistConfiguration {
    enum ConfigurationError: Error {
        case missingFile
        case invalidFormat
    }

    static let shared: UserStudyPlistConfiguration = {
        do {
            return try loadFromBundle()
        } catch {
            #if DEBUG
            print("OpenAI configuration not available: \(error)")
            #endif
            return UserStudyPlistConfiguration(apiKey: nil, isUserStudyEnabled: false)
        }
    }()

    /// The OpenAI API key loaded from the configuration file.
    /// Will be nil if the configuration file is missing or invalid.
    let apiKey: String?

    /// Indicates whether the user study features are enabled.
    let isUserStudyEnabled: Bool

    private static func loadFromBundle() throws -> UserStudyPlistConfiguration {
        guard let url = Bundle.main.url(forResource: "UserStudyConfig", withExtension: "plist") else {
            throw ConfigurationError.missingFile
        }

        let data = try Data(contentsOf: url)
        let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        guard let plist = dict,
              let apiKey = plist["OpenAIAPIKey"] as? String,
              let isUserStudyEnabled = plist["UserStudyEnabled"] as? Bool
        else {
            throw ConfigurationError.invalidFormat
        }

        return UserStudyPlistConfiguration(apiKey: apiKey, isUserStudyEnabled: isUserStudyEnabled)
    }
}
