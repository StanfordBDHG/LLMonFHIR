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
            // using short keys to reduce the amount of data going into the QR code.
            case studyId = "s"
            case expires = "e"
            case userInfo = "i"
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
                userInfo: participantId.isEmpty ? [:] : ["pid": participantId]
            )
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            studyId = try container.decode(String.self, forKey: .studyId)
            expires = try container.decodeIfPresent(Date.self, forKey: .expires)
            userInfo = try container.decodeIfPresent([String: String].self, forKey: .userInfo) ?? [:]
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
    }
}


extension StudyQRCodeHandler.QRCodePayload {
    init(qrCodePayload payload: String) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .roundedUnixTimestamp
        let data = Data(payload.utf8)
        self = try decoder.decode(Self.self, from: data)
    }
    
    func qrCodePayload() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .roundedUnixTimestamp
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}


extension JSONEncoder.DateEncodingStrategy {
    /// A date encoding strategy that represents `Date` values as floored unix timestamps (i.e., rounded down to the next second).
    ///
    /// The motivation here is to be able to save on bytes when storing a `Date` in a QR code.
    /// This does result in a small loss in precision, but allows us to save ~41% of the bytes required to store the value.
    static let roundedUnixTimestamp = Self.custom { date, encoder in
        let timestamp = Int(date.timeIntervalSince1970)
        var container = encoder.singleValueContainer()
        try container.encode(timestamp)
    }
}


extension JSONDecoder.DateDecodingStrategy {
    /// A date decoding strategy that represents `Date` values as floored unix timestamps (i.e., rounded down to the next second).
    ///
    /// The motivation here is to be able to save on bytes when storing a `Date` in a QR code.
    /// This does result in a small loss in precision, but allows us to save ~41% of the bytes required to store the value.
    static let roundedUnixTimestamp = Self.custom { decoder in
        let container = try decoder.singleValueContainer()
        let timestamp = try container.decode(Int.self)
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
