//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import LLMonFHIRShared


extension Study {
    /// All studies currently available.
    public static var allStudies: [Study] {
        [.usabilityStudy, .gynStudy, .spineAI]
    }
}

extension Study {
    /// Fetches the study with the specified id, if available.
    public static func withId(_ id: Study.ID) -> Study? {
        allStudies.first { $0.id == id }
    }
}
