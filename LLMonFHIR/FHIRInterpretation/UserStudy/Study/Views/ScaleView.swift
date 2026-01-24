//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SwiftUI


@MainActor
@Observable
final class ScaleAnswerState {
    private(set) var answers: [Int: Int] = [:]

    func update(value: Int, at index: Int) {
        answers[index] = value
    }

    func isAnswered(questionIndex: Int, isOptional: Bool) -> Bool {
        if isOptional {
            return true
        }
        return answers[questionIndex] != nil
    }
}

/// A view for collecting scale responses
struct ScaleView: View {
    /// The index of this question
    let index: Int

    /// The response options for this question
    let responseOptions: TaskQuestionType.AnswerOptions

    /// The state object for managing answers
    let answerState: ScaleAnswerState

    private var range: ClosedRange<Int> {
        1...responseOptions.count
    }


    var body: some View {
        RadioSelectionView(
            range: range,
            selectedValue: answerState.answers[index],
            displayText: { value in
                guard value > 0 && value <= responseOptions.count else {
                    return ""
                }
                return responseOptions[value - 1]
            },
            onSelect: { value in
                answerState.update(value: value, at: index)
            }
        )
    }
}
