//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum FHIRResourceProcessorError: LocalizedError {
    case notParsableAsAString
    
    var errorDescription: String? {
        switch self {
        case .notParsableAsAString:
            String(
                localized: "Unable to parse result of the LLM prompt.",
                comment: "Error thrown if the result can not be parsed in the underlying type."
            )
        }
    }
}
