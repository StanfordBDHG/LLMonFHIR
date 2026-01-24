//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


/// Manages the state of answers for different types of survey questions
@MainActor
@Observable
final class SurveyAnswerState {
    let scaleState = ScaleAnswerState()
    let freeTextState = FreeTextAnswerState()
    let npsState = NPSAnswerState()

    func getAnswers(for questions: [TaskQuestion]) -> [TaskQuestionAnswer] {
        questions.enumerated().map { index, question in
            switch question.type {
            case .scale:
                scaleState.answers[index].map { .scale($0) } ?? .unanswered
            case .freeText:
                freeTextState.answers[index].map { .freeText($0) } ?? .unanswered
            case .netPromoterScore:
                npsState.answer.map { .netPromoterScore($0) } ?? .unanswered
            case .instructional:
                .unanswered
            }
        }
    }

    func isAnswered(questionIndex: Int, type: TaskQuestionType, isOptional: Bool) -> Bool {
        switch type {
        case .instructional:
            true
        case .scale:
            scaleState.isAnswered(questionIndex: questionIndex, isOptional: isOptional)
        case .freeText:
            freeTextState.isAnswered(questionIndex: questionIndex, isOptional: isOptional)
        case .netPromoterScore:
            npsState.isAnswered(isOptional: isOptional)
        }
    }
}
