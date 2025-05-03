//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents a group of related questions in a survey
struct SurveyTask: Identifiable {
    /// Unique identifier for the task
    let id: Int

    /// Optional instructions displayed to the user
    let instruction: String?

    /// The questions contained in this task
    private(set) var questions: [TaskQuestion]

    /// Updates the answer for a specific question in this task
    /// - Parameters:
    ///   - answer: The new answer to store
    ///   - index: The index of the question to update
    /// - Throws: `SurveyError` if the index is invalid or the answer is invalid
    mutating func updateAnswer(_ answer: TaskQuestionAnswer, forQuestionIndex index: Int) throws {
        guard questions.indices.contains(index) else {
            throw SurveyError.invalidQuestionIndex
        }
        try questions[index].updateAnswer(answer)
    }
}
