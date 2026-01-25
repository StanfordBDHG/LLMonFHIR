//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import class ModelsR4.Questionnaire


extension Questionnaire {
    static func named(_ nameInBundle: String) throws -> Questionnaire {
        guard let url = Bundle.module.url(forResource: nameInBundle, withExtension: "json") else {
            throw NSError(domain: "edu.stanford.LLMonFHIRShared", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unable to find resource '\(nameInBundle).json'"
            ])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Questionnaire.self, from: data)
    }
}
