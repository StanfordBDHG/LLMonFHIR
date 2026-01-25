//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import CryptoKit
import Foundation
import LLMonFHIRShared
import LLMonFHIRStudyDefinitions
import class ModelsR4.Questionnaire
import Testing


@Suite
struct LLMonFHIRSharedTests {
    @Test
    func encryptAndDecrypt() throws {
        let publicKey = try Curve25519.KeyAgreement.PublicKey(
            contentsOf: try #require(Bundle.module.url(forResource: "public_key", withExtension: "pem"))
        )
        let privateKey = try Curve25519.KeyAgreement.PrivateKey(
            contentsOf: try #require(Bundle.module.url(forResource: "private_key", withExtension: "pem"))
        )
        let data = try #require("Hello Spezi :) 🚀🚀🚀🚀🚀🚀🚀".data(using: .utf8))
        let encrypted = try data.encrypted(using: publicKey)
        let decrypted = try encrypted.decrypted(using: privateKey)
        #expect(decrypted == data)
    }
    
    @Test
    func studyInitialQuestionnaireEncodingAndDecoding() throws {
        for study in Study.allStudies {
            guard let questionnaire = study.initialQuestionnaire else {
                continue
            }
            let jsonEncoded = try JSONEncoder().encode(questionnaire)
            let jsonDecoded = try JSONDecoder().decode(Questionnaire.self, from: jsonEncoded)
            #expect(jsonDecoded.isEqual(to: questionnaire))
            let plistEncoded = try PropertyListEncoder().encode(questionnaire)
            let plistDecoded = try PropertyListDecoder().decode(Questionnaire.self, from: plistEncoded)
            #expect(plistDecoded.isEqual(to: questionnaire))
        }
    }
}
