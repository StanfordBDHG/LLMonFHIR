//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SwiftUI


/// A view that displays a single question and its corresponding input method
struct TaskQuestionView: View {
    /// The question to display
    let question: Study.Task.Question

    /// The index of this question in the task
    let index: Int

    /// The shared state object for managing answers
    let answerState: SurveyAnswerState


    var body: some View {
        Section {
            questionContent
        } header: {
            if question.type != .instructional {
                Text(question.isOptional ? "\(question.text) (Optional)" : question.text)
                    .textCase(.none)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
    }


    @ViewBuilder private var questionContent: some View {
        switch question.type {
        case .instructional:
            Text(question.text)
        case .scale(let responseOptions):
            ScaleView(
                index: index,
                responseOptions: responseOptions,
                answerState: answerState.scaleState
            )
        case .freeText:
            FreeTextView(
                index: index,
                answerState: answerState.freeTextState
            )
        case .netPromoterScore(let range):
            NPSView(
                range: range,
                answerState: answerState.npsState
            )
        }
    }
}
