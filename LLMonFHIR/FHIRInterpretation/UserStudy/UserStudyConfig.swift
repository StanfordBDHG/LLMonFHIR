//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation


struct UserStudyConfig {
    /// The OpenAI API key loaded from the configuration file.
    ///
    /// Will be nil if the configuration file is missing or invalid.
    let apiKey: String?

    /// Indicates whether the user study features are enabled.
    let isUserStudyEnabled: Bool
    
    /// The public key to use when encrypting a report file.
    ///
    /// `nil` if the files should never be encrypted.
    let encryptionKey: Curve25519.KeyAgreement.PublicKey?
}


extension UserStudyConfig {
    enum ConfigFileError: Error {
        case missingFile
    }
    
    /// Creates an empty config suitable for a disabled user study.
    init() {
        apiKey = nil
        isUserStudyEnabled = false
        encryptionKey = nil
    }
    
    /// Creates a user study config from a property list file.
    init(plistFileAt url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try PropertyListDecoder().decode(Self.self, from: data)
    }
}


extension UserStudyConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case apiKey = "OPENAI_API_KEY"
        case isUserStudyEnabled = "IS_USER_STUDY_ENABLED"
        case encryptionKey = "ENCRYPTION_KEY"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey)
        isUserStudyEnabled = try container.decode(Bool.self, forKey: .isUserStudyEnabled)
        encryptionKey = try container.decodeIfPresent(Data.self, forKey: .encryptionKey).flatMap { $0.isEmpty ? nil : try .init(pemFileContents: $0) }
    }
}


extension UserStudyConfig {
    static let shared: Self = {
        do {
            return try loadFromBundle()
        } catch {
            #if DEBUG
            print("Error loading UserStudy config: \(error)")
            #endif
            return Self()
        }
    }()
    
    
    private static func loadFromBundle() throws -> Self {
        guard let url = Bundle.main.url(forResource: "UserStudyConfig", withExtension: "plist") else {
            throw ConfigFileError.missingFile
        }
        return try Self(plistFileAt: url)
    }
}
