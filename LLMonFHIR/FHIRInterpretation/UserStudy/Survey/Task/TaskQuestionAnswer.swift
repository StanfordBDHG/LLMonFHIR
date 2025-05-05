//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents a user's response to a survey question
enum TaskQuestionAnswer: Equatable {
    case scale(Int)
    case freeText(String)
    case netPromoterScore(Int)
    case unanswered

    var rawValue: String {
        switch self {
        case .scale(let value):
            "\(value)"
        case .freeText(let value):
            "\(value)"
        case .netPromoterScore(let value):
            "\(value)"
        case .unanswered:
            "unanswered"
        }
    }
}
