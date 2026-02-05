//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


public enum AppLaunchMode: Equatable, Sendable {
    /// The app is used by a user who needs to supply their own API key, and then can use the chat.
    case standalone
    case test
    /// The app is used to select and enroll in a study.
    /// - parameter studyId: Optional; the id of the study which the app should automatically start upon launch,
    case study(studyId: String?)
}


extension AppLaunchMode: RawRepresentable, Codable {
    public var rawValue: String {
        switch self {
        case .standalone:
            "standalone"
        case .test:
            "test"
        case .study(studyId: .none):
            "study"
        case .study(studyId: .some(let studyId)):
            "study:\(studyId)"
        }
    }
    
    public init?(rawValue: String) {
        if rawValue == Self.standalone.rawValue {
            self = .standalone
        } else if rawValue == Self.test.rawValue {
            self = .test
        } else if rawValue == Self.study(studyId: nil).rawValue {
            self = .study(studyId: nil)
        } else if rawValue.starts(with: "study:"), let colonIdx = rawValue.firstIndex(of: ":") {
            self = .study(studyId: String(rawValue[rawValue.index(after: colonIdx)...]))
        } else {
            return nil
        }
    }
}
