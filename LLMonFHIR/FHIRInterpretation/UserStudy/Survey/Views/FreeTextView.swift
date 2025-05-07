//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


@MainActor
@Observable
final class FreeTextAnswerState {
    private(set) var answers: [Int: String] = [:]

    func update(_ text: String, at index: Int) {
        answers[index] = text
    }

    func isAnswered(questionIndex: Int, isOptional: Bool) -> Bool {
        if isOptional {
            return true
        }
        return answers[questionIndex]?.isEmpty == false
    }
}

/// A view for collecting free text responses
struct FreeTextView: View {
    /// The index of this question
    let index: Int

    /// The state object for managing answers
    let answerState: FreeTextAnswerState


    var body: some View {
        TextEditor(text: binding)
            .frame(height: 100)
    }


    private var binding: Binding<String> {
        Binding(
            get: { answerState.answers[index] ?? "" },
            set: { answerState.update($0, at: index) }
        )
    }
}
