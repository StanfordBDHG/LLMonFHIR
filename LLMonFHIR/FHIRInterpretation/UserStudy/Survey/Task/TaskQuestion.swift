//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents a single question in a survey
struct TaskQuestion {
    /// The text of the question presented to the user
    let text: String

    /// The type of question, determining what kinds of answers are valid
    let type: TaskQuestionType

    /// Indicates whether the question can be skipped
    let isOptional: Bool

    /// The current answer to this question
    private(set) var answer: TaskQuestionAnswer = .unanswered


    /// Creates a new survey question
    /// - Parameters:
    ///   - text: The question text to display
    ///   - type: The type of question and its validation rules
    ///   - isOptional: Whether the question can be skipped, defaults to false
    init(text: String, type: TaskQuestionType, isOptional: Bool = false) {
        self.text = text
        self.type = type
        self.isOptional = isOptional
    }


    /// Updates the answer for this question
    /// - Parameter answer: The new answer to store
    /// - Throws: `SurveyError` if the answer is invalid for this question type
    mutating func updateAnswer(_ answer: TaskQuestionAnswer) throws {
        if isOptional && answer == .unanswered {
            self.answer = answer
            return
        }

        try validateAnswer(answer)
        self.answer = answer
    }

    private func validateAnswer(_ answer: TaskQuestionAnswer) throws {
        switch (type, answer) {
        case let (.scale(responseOptions), .scale(value)):
            guard let validRange = type.range else {
                throw SurveyError.invalidRange(expected: 1...responseOptions.count)
            }

            guard validRange.contains(value) else {
                throw SurveyError.invalidRange(expected: validRange)
            }
        case let (.netPromoterScore(range), .netPromoterScore(value)):
            guard range.contains(value) else {
                throw SurveyError.invalidRange(expected: range)
            }
        case (.freeText, .freeText):
            return
        default:
            throw SurveyError.typeMismatch
        }
    }
}
