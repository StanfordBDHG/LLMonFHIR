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
    }
    
    let appLaunchMode: LLMonFHIR.Mode
    let studies: [Study]
    
    init(launchMode: LLMonFHIR.Mode, studies: [Study]) {
        self.appLaunchMode = launchMode
        self.studies = studies
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appLaunchMode = try .init(argv: ["--mode"] + container.decode(String.self, forKey: .appLaunchMode).components(separatedBy: " "))
        studies = try container.decode([Study].self, forKey: .studies)
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
            return Self(launchMode: .standalone, studies: [])
        }
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode(Self.self, from: data)
        } catch {
            return Self(launchMode: .standalone, studies: [])
        }
    }
}
