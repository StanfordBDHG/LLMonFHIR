//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

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
                return scaleState.answers[index].map { .scale($0) } ?? .unanswered
            case .freeText:
                return  freeTextState.answers[index].map { .freeText($0) } ?? .unanswered
            case .netPromoterScore:
                return npsState.answer.map { .netPromoterScore($0) } ?? .unanswered
            }
        }
    }

    func isAnswered(questionIndex: Int, type: TaskQuestionType, isOptional: Bool) -> Bool {
        switch type {
        case .scale:
            return scaleState.isAnswered(questionIndex: questionIndex, isOptional: isOptional)
        case .freeText:
            return freeTextState.isAnswered(questionIndex: questionIndex, isOptional: isOptional)
        case .netPromoterScore:
            return npsState.isAnswered(isOptional: isOptional)
        }
    }
}

/// The main view for displaying and collecting survey responses
struct SurveyView: View {
    /// The task containing the questions to display
    let task: SurveyTask

    /// Controls whether this view is currently displayed
    @Binding var isPresented: Bool

    /// Callback to invoke when the survey is submitted
    let onSubmit: ([TaskQuestionAnswer]) -> Void

    /// The state object managing all answers
    @State private var answerState = SurveyAnswerState()


    var body: some View {
        NavigationView {
            Form {
                questionSections
                submitButtonSection
            }
            .navigationTitle("Task \(task.id)")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(trailing: cancelButton)
        }
    }
    

    private var questionSections: some View {
        ForEach(Array(task.questions.enumerated()), id: \.offset) { index, question in
            TaskQuestionView(
                question: question,
                index: index,
                answerState: answerState
            )
        }
    }

    private var submitButtonSection: some View {
        Button(action: handleSubmit) {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .padding(4)
        }
            .padding(.horizontal, -16)
            .buttonStyle(.borderedProminent)
            .disabled(!areAllQuestionsAnswered)
            .listRowBackground(Color.clear)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            isPresented = false
        }
    }

    private var areAllQuestionsAnswered: Bool {
        task.questions.indices.allSatisfy { index in
            let question = task.questions[index]
            return answerState.isAnswered(
                questionIndex: index,
                type: question.type,
                isOptional: question.isOptional
            )
        }
    }

    private func handleSubmit() {
        let answers = answerState.getAnswers(for: task.questions)
        onSubmit(answers)
        isPresented = false
    }
}
