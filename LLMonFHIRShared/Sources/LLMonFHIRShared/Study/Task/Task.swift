//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable function_default_parameter_at_end

import Foundation


extension Study {
    /// Represents a group of related questions in a survey
    public struct Task: Hashable, Identifiable, Sendable {
        /// Unique identifier for the task
        public let id: String
        public let title: String?
        /// Optional instructions displayed to the user
        public let instructions: String?
        
        public let assistantMessagesLimit: ClosedRange<Int>?
        
        /// The questions contained in this task
        public private(set) var questions: [Question]
        
        public init(
            id: String,
            title: String? = nil,
            instructions: String?,
            assistantMessagesLimit: ClosedRange<Int>? = nil,
            questions: [Question]
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
        /// - Throws: `StudyError` if the index is invalid or the answer is invalid
        public mutating func updateAnswer(_ answer: Question.Answer, forQuestionIndex index: Int) throws(StudyError) {
            guard questions.indices.contains(index) else {
                throw StudyError.invalidQuestionIndex
            }
            try questions[index].updateAnswer(answer)
        }
    }
}
