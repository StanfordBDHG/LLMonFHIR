//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation


extension Curve25519.KeyAgreement.PublicKey {
    init(pemFileContents: Data) throws {
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
}


extension Data {
    func encrypted(using publicKey: Curve25519.KeyAgreement.PublicKey) throws -> Data {
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
}
