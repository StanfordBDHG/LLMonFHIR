//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import CryptoKit
public import Foundation


extension Curve25519.KeyAgreement.PublicKey: @retroactive Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawRepresentation)
    }
}

extension Curve25519.KeyAgreement.PrivateKey: @retroactive Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawRepresentation == rhs.rawRepresentation
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawRepresentation)
    }
}


extension Curve25519.KeyAgreement.PublicKey {
    /// The key, as a PEM file.
    public var pemFileContents: Data {
        // The standard ASN.1 header for X25519 (OID: 1.3.101.110)
        // Structure: Sequence(42) { Sequence(5) { OID(3) }, BitString(33) { Unused(0) + Key(32) } }
        var data = Data([ // start off with the x25519Header
            0x30, 0x2A, // Sequence of 42 bytes
            0x30, 0x05, // Sequence of 5 bytes (Algorithm Identifier)
            0x06, 0x03, 0x2B, 0x65, 0x6E, // OID: 1.3.101.110 (X25519)
            0x03, 0x21, 0x00 // Bit String of 33 bytes (0 unused bits)
        ])
        data.append(self.rawRepresentation)
        let base64 = data.base64EncodedString(options: .lineLength64Characters)
        return Data("-----BEGIN PUBLIC KEY-----\n\(base64)\n-----END PUBLIC KEY-----\n".utf8)
    }
    
    /// Creates a Curve25519 public key from the specified `Data`
    public init(pemFileContents: Data) throws {
        let possiblePrefix = Data("-----BEGIN PUBLIC KEY-----\n".utf8)
        let possibleSuffix = Data("\n-----END PUBLIC KEY-----\n".utf8)
        var data = pemFileContents
        if data.starts(with: possiblePrefix) && data.ends(with: possibleSuffix) {
            guard let decoded = Data(base64Encoded: Data(data.dropFirst(possiblePrefix.count).dropLast(possibleSuffix.count))) else {
                // unreachable if the correct file was injected into the plist
                throw NSError(domain: "edu.stanford.LLMonFHIR", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to parse key"
                ])
            }
            data = decoded
        }
        try self.init(rawRepresentation: data.suffix(32))
    }
    
    /// Creates a Curve25519 public key from the contents of a file.
    public init(contentsOf url: URL) throws {
        try self.init(pemFileContents: Data(contentsOf: url))
    }
}


extension Curve25519.KeyAgreement.PrivateKey {
    /// The key, as a PEM file.
    public var pemFileContents: Data {
        // The standard PKCS#8 ASN.1 header for X25519 Private Keys
        // Structure: Sequence(46) { Version(0), AlgorithmIdentifier(OID 1.3.101.110), OctetString(34) { OctetString(32) } }
        var data = Data([
            0x30, 0x2E, // Sequence of 46 bytes
            0x02, 0x01, 0x00, // Version: 0
            0x30, 0x05, // Sequence of 5 bytes (Algorithm Identifier)
            0x06, 0x03, 0x2B, 0x65, 0x6E, // OID: 1.3.101.110 (X25519)
            0x04, 0x22, // Octet String of 34 bytes
            0x04, 0x20  // Octet String of 32 bytes (The Key)
        ])
        data.append(self.rawRepresentation)
        let base64 = data.base64EncodedString(options: .lineLength64Characters)
        return Data("-----BEGIN PRIVATE KEY-----\n\(base64)\n-----END PRIVATE KEY-----\n".utf8)
    }
    
    /// Creates a Curve25519 private key from the specified `Data`
    public init(pemFileContents: Data) throws {
        let possiblePrefix = Data("-----BEGIN PRIVATE KEY-----\n".utf8)
        let possibleSuffix = Data("\n-----END PRIVATE KEY-----\n".utf8)
        var data = pemFileContents
        if data.starts(with: possiblePrefix) && data.ends(with: possibleSuffix) {
            guard let decoded = Data(base64Encoded: Data(data.dropFirst(possiblePrefix.count).dropLast(possibleSuffix.count))) else {
                throw NSError(domain: "edu.stanford.LLMonFHIR", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to parse private key"
                ])
            }
            data = decoded
        }
        // Extract the last 32 bytes (the raw key), ignoring the ASN.1 header
        try self.init(rawRepresentation: data.suffix(32))
    }
    
    /// Creates a Curve25519 private key from the contents of a file.
    public init(contentsOf url: URL) throws {
        try self.init(pemFileContents: Data(contentsOf: url))
    }
}


extension Data {
    /// Encrypts the data, using the specified public key.
    public func encrypted(using publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Data {
        let ephemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: publicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        let sealedBox = try AES.GCM.seal(self, using: symmetricKey)
        let ephemeralPublicKeyData = ephemeralPrivateKey.publicKey.rawRepresentation
        guard let data = sealedBox.combined else {
            throw NSError(domain: "edu.stanford.LLMonFHIR", code: 123)
        }
        return ephemeralPublicKeyData + data
    }
    
    
    /// Encrypts the data, using the specified private key.
    public func decrypted(using privateKey: Curve25519.KeyAgreement.PrivateKey) throws -> Data {
        // The first 32 bytes are the ephemeral public key.
        guard self.count > 32 else {
            throw NSError(domain: "edu.stanford.LLMonFHIR", code: 124, userInfo: [
                NSLocalizedDescriptionKey: "Data too short to contain public key and ciphertext"
            ])
        }
        let ephemeralPublicKeyData = self.prefix(32)
        let ciphertext = self.dropFirst(32)
        let ephemeralPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: ephemeralPublicKeyData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}
