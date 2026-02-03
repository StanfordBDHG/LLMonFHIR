//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CryptoKit
import Foundation


public struct StudyConfig: Hashable, Codable, Sendable {
    public enum OpenAIEndpointConfig: Hashable, Sendable {
        /// The study uses the regular OpenAI API to generate chat completions
        case regular
        /// The study uses a firebase function to generate chat completions
        case firebaseFunction(name: String)
    }
    
    /// The OpenAI API key that should be used when answering this survey.
    public let openAIAPIKey: String
    public let openAIEndpoint: OpenAIEndpointConfig
    
    /// The email address to which the report file should be sent.
    public let reportEmail: String
    
    /// The public key to use when encrypting a report file.
    ///
    /// `nil` if the files should never be encrypted.
    public let encryptionKey: Curve25519.KeyAgreement.PublicKey?
    
    public init(
        openAIAPIKey: String,
        openAIEndpoint: OpenAIEndpointConfig,
        reportEmail: String,
        encryptionKey: Curve25519.KeyAgreement.PublicKey?
    ) {
        self.openAIAPIKey = openAIAPIKey
        self.openAIEndpoint = openAIEndpoint
        self.reportEmail = reportEmail
        self.encryptionKey = encryptionKey
    }
}


extension StudyConfig.OpenAIEndpointConfig: RawRepresentable, Codable {
    public var rawValue: String {
        switch self {
        case .regular:
            "regular"
        case .firebaseFunction(let name):
            "firebase-function:\(name)"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "regular":
            self = .regular
        case let value where value.starts(with: "firebase-function:"):
            let idx = value.firstIndex(of: ":")! // swiftlint:disable:this force_unwrapping
            let name = String(value[value.index(after: idx)...])
            self = .firebaseFunction(name: name)
        default:
            return nil
        }
    }
}


extension Curve25519.KeyAgreement.PublicKey: @retroactive Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(pemFileContents: data)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.pemFileContents)
    }
}
