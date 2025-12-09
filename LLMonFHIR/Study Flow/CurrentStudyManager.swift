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


@MainActor
@Observable
final class CurrentStudyManager: Module, EnvironmentAccessible, Sendable {
    enum StudyActivationError: Error {
        case failedParsingQRCodePayload(any Error)
        case expiredTimestamp
        /// Another study is already active
        case alreadyActive
        /// Unable to find a study for the specified id
        case unknownStudy
    }
    
    @ObservationIgnored @Application(\.logger) private var logger
    
    private(set) var currentSurvey: Survey?
    
    
    func configure() {
        if let studyId = FeatureFlags.enabledUserStudyId {
            do {
                try startStudy(withId: studyId)
            } catch {
                logger.error("Unable to start feature-flag-triggered study '\(studyId)'")
            }
        }
    }
    
    
    func handleQRCode(payload payloadString: String) throws(StudyActivationError) {
        let payload: QRCodePayload
        do {
            payload = try QRCodePayload(qrCodePayload: payloadString)
        } catch {
            throw .failedParsingQRCodePayload(error)
        }
        if let expirationTimestamp = payload.expires, expirationTimestamp < .now {
            throw .expiredTimestamp
        }
        try startStudy(withId: payload.studyId)
    }
    
    
    func startStudy(withId studyId: String) throws(StudyActivationError) {
        guard currentSurvey == nil || currentSurvey?.id == studyId else {
            throw .alreadyActive
        }
        guard let study = Survey.withId(studyId) else {
            throw .unknownStudy
        }
        currentSurvey = study
    }
}


extension CurrentStudyManager {
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
