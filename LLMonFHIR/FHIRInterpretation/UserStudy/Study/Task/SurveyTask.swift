//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable function_default_parameter_at_end

import Foundation


/// Represents a group of related questions in a survey
struct SurveyTask: Hashable, Identifiable, Sendable {
    /// Unique identifier for the task
    let id: String
    let title: String?
    /// Optional instructions displayed to the user
    let instructions: String?
    
    let assistantMessagesLimit: ClosedRange<Int>?

    /// The questions contained in this task
    private(set) var questions: [TaskQuestion]
    
    init(
        id: String,
        title: String? = nil,
        instructions: String?,
        assistantMessagesLimit: ClosedRange<Int>? = nil,
        questions: [TaskQuestion]
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.assistantMessagesLimit = assistantMessagesLimit
        self.questions = questions
    }

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
