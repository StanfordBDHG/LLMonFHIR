//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension Survey {
    private struct PlistWrapper: Codable {
        let studies: [Survey]
    }
    
    static func withId(_ id: String) -> Survey? {
        guard let url = Bundle.main.url(forResource: "UserStudyConfig", withExtension: "plist") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let allSurveys = try PropertyListDecoder().decode(PlistWrapper.self, from: data).studies
            return allSurveys.first { $0.id == id }
        } catch {
            return nil
        }
    }
}
