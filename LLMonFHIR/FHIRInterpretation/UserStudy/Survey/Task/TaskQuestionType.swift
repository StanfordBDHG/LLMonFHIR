//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Defines the type of question and its validation rules
enum TaskQuestionType {
    case scale(responseOptions: [String])
    case freeText
    case netPromoterScore(range: ClosedRange<Int>)

    var range: ClosedRange<Int>? {
        switch self {
        case .scale(let responseOptions):
            return 1...(responseOptions.count)
        case .netPromoterScore(let range):
            return range
        case .freeText:
            return nil
        }
    }
}
