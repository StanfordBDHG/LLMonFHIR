//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


struct AppConfigFile: Codable {
    private enum CodingKeys: String, CodingKey {
        case appLaunchMode
        case studies
        case firebaseConfig
    }
    
    let appLaunchMode: LLMonFHIR.Mode
    let studies: [Study]
    let firebaseConfig: FirebaseConfigDictionary?
    
    init(launchMode: LLMonFHIR.Mode, studies: [Study], firebaseConfig: FirebaseConfigDictionary?) {
        self.appLaunchMode = launchMode
        self.studies = studies
        self.firebaseConfig = firebaseConfig
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appLaunchMode = try .init(argv: ["--mode"] + container.decode(String.self, forKey: .appLaunchMode).components(separatedBy: " "))
        studies = try container.decode([Study].self, forKey: .studies)
        firebaseConfig = try container.decodeIfPresent(FirebaseConfigDictionary.self, forKey: .firebaseConfig)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch appLaunchMode {
        case .standalone:
            try container.encode("standalone", forKey: .appLaunchMode)
        case .test:
            try container.encode("test", forKey: .appLaunchMode)
        case .study(let studyId):
            if let studyId {
                try container.encode("study \(studyId)", forKey: .appLaunchMode)
            } else {
                try container.encode("study", forKey: .appLaunchMode)
            }
        }
        try container.encode(studies, forKey: .studies)
    }
}


extension AppConfigFile {
    /// The configuration bundled with the app.
    ///
    /// Returns an empty ``LLMonFHIR/LLMonFHIR/Mode/standalone`` config if the file is not present or cannot be decoded.
    static func current() -> Self {
        guard let url = Bundle.main.url(forResource: "UserStudyConfig", withExtension: "plist") else {
            return Self(launchMode: .standalone, studies: [], firebaseConfig: nil)
        }
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode(Self.self, from: data)
        } catch {
            return Self(launchMode: .standalone, studies: [], firebaseConfig: nil)
        }
    }
}


extension AppConfigFile {
    struct FirebaseConfigDictionary: Codable {
        private enum Value: Codable {
            case bool(Bool)
            case string(String)
            
            var anyValue: Any {
                switch self {
                case .bool(let value):
                    value
                case .string(let value):
                    value
                }
            }
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let value = try? container.decode(String.self) {
                    self = .string(value)
                } else if let value = try? container.decode(Bool.self) {
                    self = .bool(value)
                } else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
                }
            }
            
            func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .bool(let value):
                    try container.encode(value)
                case .string(let value):
                    try container.encode(value)
                }
            }
        }
        
        private let entries: [String: Value]
        
        private init(_ entries: [String: Value]) {
            self.entries = entries
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            entries = try container.decode([String: Value].self)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(entries)
        }
        
        // swiftlint:disable legacy_objc_type
        func asNSDictionary() -> NSDictionary {
            NSDictionary(dictionary: entries.mapValues(\.anyValue))
        }
        // swiftlint:enable legacy_objc_type
    }
}
