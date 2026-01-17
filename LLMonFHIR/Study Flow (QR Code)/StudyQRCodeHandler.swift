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
    
    struct ScanResult: Hashable {
        let study: Study
        let userInfo: [String: String]
    }
    
    static func processQRCode(payload payloadString: String) throws(StudyActivationError) -> ScanResult {
        let payload: QRCodePayload
        do {
            payload = try QRCodePayload(qrCodePayload: payloadString)
        } catch {
            throw .failedParsingQRCodePayload(error)
        }
        guard let study = AppConfigFile.current().studies.first(where: { $0.id == payload.studyId }) else {
            throw .unknownStudy
        }
        if let expirationTimestamp = payload.expires, expirationTimestamp < .now {
            throw .expiredTimestamp
        }
        return ScanResult(study: study, userInfo: payload.userInfo)
    }
}


extension StudyQRCodeHandler {
    struct QRCodePayload: Codable {
        enum CodingKeys: String, CodingKey {
            case studyId = "id"
            case expires
            case userInfo
        }
        
        let studyId: String
        let expires: Date?
        let userInfo: [String: String]
        
        init(studyId: String, expires: Date?, userInfo: [String: String]) {
            self.studyId = studyId
            self.expires = expires
            self.userInfo = userInfo
        }
        
        init(studyId: String, expires: Date?, participantId: String) {
            self.init(
                studyId: studyId,
                expires: expires,
                userInfo: participantId.isEmpty ? [:] : ["participantId": participantId]
            )
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            studyId = try container.decode(String.self, forKey: .studyId)
            expires = try container.decodeIfPresent(Date.self, forKey: .expires)
            userInfo = try container.decodeIfPresent([String: String].self, forKey: .userInfo) ?? [:]
        }
        
        init(qrCodePayload payload: String) throws {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = Data(payload.utf8)
            self = try decoder.decode(Self.self, from: data)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(studyId, forKey: .studyId)
            try container.encodeIfPresent(expires, forKey: .expires)
            try container.encodeIfPresent(
                userInfo.isEmpty ? nil : userInfo,
                forKey: .userInfo
            )
        }
        
        func qrCodePayload() throws -> String {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            return String(decoding: data, as: UTF8.self)
        }
    }
}
