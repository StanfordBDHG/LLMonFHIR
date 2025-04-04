//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


// MARK: - Answer Types

/// Represents a user's response to a survey question
enum Answer: Equatable {
    case likertScale(Int)
    case freeText(String)
    case netPromoterScore(Int)
    case unanswered

    var rawValue: String {
        switch self {
        case .likertScale(let value):
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


/// Defines the type of question and its validation rules
enum QuestionType {
    case likertScale(responseOptions: [String])
    case freeText
    case netPromoterScore(range: ClosedRange<Int>)

    var range: ClosedRange<Int>? {
        switch self {
        case .likertScale(let responseOptions):
            return 1...(responseOptions.count)
        case .netPromoterScore(let range):
            return range
        case .freeText:
            return nil
        }
    }
}


// MARK: - Error Handling

/// Represents errors that can occur during survey operations
enum SurveyError: LocalizedError {
    /// Indicates a numerical response was outside the valid range
    case invalidRange(expected: ClosedRange<Int>)

    /// Indicates the answer type didn't match the question type
    case typeMismatch

    /// Indicates an attempt to access a question at an invalid index
    case invalidQuestionIndex

    /// Indicates an attempt to access a task that doesn't exist
    case taskNotFound

    var errorDescription: String? {
        switch self {
        case .invalidRange(let range):
            return "Value must be between \(range.lowerBound) and \(range.upperBound)"
        case .typeMismatch:
            return "Answer type doesn't match question type"
        case .invalidQuestionIndex:
            return "Question index out of bounds"
        case .taskNotFound:
            return "Task not found"
        }
    }
}


// MARK: - Survey Components

/// Represents a single question in a survey
struct Question {
    /// The text of the question presented to the user
    let text: String

    /// The type of question, determining what kinds of answers are valid
    let type: QuestionType

    /// Indicates whether the question can be skipped
    let isOptional: Bool

    /// The current answer to this question
    private(set) var answer: Answer = .unanswered


    /// Creates a new survey question
    /// - Parameters:
    ///   - text: The question text to display
    ///   - type: The type of question and its validation rules
    ///   - isOptional: Whether the question can be skipped, defaults to false
    init(text: String, type: QuestionType, isOptional: Bool = false) {
        self.text = text
        self.type = type
        self.isOptional = isOptional
    }


    /// Updates the answer for this question
    /// - Parameter answer: The new answer to store
    /// - Throws: `SurveyError` if the answer is invalid for this question type
    mutating func updateAnswer(_ answer: Answer) throws {
        if isOptional && answer == .unanswered {
            self.answer = answer
            return
        }

        try validateAnswer(answer)
        self.answer = answer
    }

    private func validateAnswer(_ answer: Answer) throws {
        switch (type, answer) {
        case let (.likertScale(responseOptions), .likertScale(value)):
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


/// Represents a group of related questions in a survey
struct SurveyTask: Identifiable {
    /// Unique identifier for the task
    let id: Int

    /// The questions contained in this task
    private(set) var questions: [Question]

    /// Updates the answer for a specific question in this task
    /// - Parameters:
    ///   - answer: The new answer to store
    ///   - index: The index of the question to update
    /// - Throws: `SurveyError` if the index is invalid or the answer is invalid
    mutating func updateAnswer(_ answer: Answer, forQuestionIndex index: Int) throws {
        guard questions.indices.contains(index) else {
            throw SurveyError.invalidQuestionIndex
        }
        try questions[index].updateAnswer(answer)
    }
}


/// Manages a collection of survey tasks and their responses
final class Survey {
    /// The tasks that make up this survey
    private(set) var tasks: [SurveyTask]


    /// Creates a new survey with the specified tasks
    /// - Parameter tasks: The tasks that make up the survey
    init(_ tasks: [SurveyTask]) {
        self.tasks = tasks
    }


    /// Submits an answer for a specific question in a specific task
    /// - Parameters:
    ///   - answer: The answer to submit
    ///   - taskId: The ID of the task containing the question
    ///   - questionIndex: The index of the question within the task
    /// - Throws: `SurveyError` if the task or question cannot be found or the answer is invalid
    func submitAnswer(_ answer: Answer, forTaskId taskId: Int, questionIndex: Int = 0) throws {
        guard let groupIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw SurveyError.taskNotFound
        }
        try tasks[groupIndex].updateAnswer(answer, forQuestionIndex: questionIndex)
    }

    /// Resets all answers in the survey to unanswered
    func resetAllAnswers() {
        tasks = tasks.map { task in
            var newTask = task
            for index in newTask.questions.indices {
                try? newTask.updateAnswer(.unanswered, forQuestionIndex: index)
            }
            return newTask
        }
    }
}
