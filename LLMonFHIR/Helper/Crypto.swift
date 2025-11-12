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
    static let llmOnFhirFileEncryptionPublicKey: Self = {
        guard let url = Bundle.main.url(forResource: "public_key", withExtension: "pem"),
              let data = try? Data(contentsOf: url).split(separator: Unicode.UTF8.CodeUnit(ascii: "\n"))[1],
              let decodedKey = Data(base64Encoded: data),
              let key = try? Self(rawRepresentation: decodedKey.suffix(32)) else {
            fatalError("Unable to decode public key")
        }
        return key
    }()
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
