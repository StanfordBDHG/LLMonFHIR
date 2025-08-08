//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


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

    nonisolated var errorDescription: String? {
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
