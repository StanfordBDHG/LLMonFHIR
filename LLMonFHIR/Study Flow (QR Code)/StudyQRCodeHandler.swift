//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Spezi
import SpeziFoundation


enum StudyQRCodeHandler {
    enum StudyActivationError: Error {
        case failedParsingQRCodePayload(any Error)
        case expiredTimestamp
        /// Unable to find a study for the specified id
        case unknownStudy
    }
    
    
    static func processQRCode(payload payloadString: String) throws(StudyActivationError) -> Study {
        let payload: QRCodePayload
        do {
            payload = try QRCodePayload(qrCodePayload: payloadString)
        } catch {
            throw .failedParsingQRCodePayload(error)
        }
        if let expirationTimestamp = payload.expires, expirationTimestamp < .now {
            throw .expiredTimestamp
        }
        return try startStudy(withId: payload.studyId)
    }
    
    
    private static func startStudy(withId studyId: String) throws(StudyActivationError) -> Study {
        guard let study = AppConfigFile.current().studies.first(where: { $0.id == studyId }) else {
            throw .unknownStudy
        }
        return study
    }
}


extension StudyQRCodeHandler {
    struct QRCodePayload: Codable {
        enum CodingKeys: String, CodingKey {
            case studyId = "id"
            case expires
        }
        
        let studyId: String
        let expires: Date?
        
        init(studyId: String, expires: Date?) {
            self.studyId = studyId
            self.expires = expires
        }
        
        init(qrCodePayload payload: String) throws {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = Data(payload.utf8)
            self = try decoder.decode(Self.self, from: data)
        }
        
        func qrCodePayload() throws -> String {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            return String(decoding: data, as: UTF8.self)
        }
    }
}
