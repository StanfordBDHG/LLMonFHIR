//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

extension String {
    var moduleLocalized: String {
        String(localized: LocalizationValue(self))
    }
}
