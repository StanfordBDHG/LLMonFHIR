//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


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
    func submitAnswer(_ answer: TaskQuestionAnswer, forTaskId taskId: Int, questionIndex: Int = 0) throws {
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
