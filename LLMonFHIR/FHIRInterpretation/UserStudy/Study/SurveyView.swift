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
    
    /// The task's index within its containing survey
    let taskIdx: Int

    /// Controls whether this view is currently displayed
    @Binding var isPresented: Bool

    /// Callback to invoke when the survey is submitted
    let onSubmit: ([TaskQuestionAnswer]) async -> Void

    /// The state object managing all answers
    @State private var answerState = SurveyAnswerState()
    
    @State private var viewState: ViewState = .idle


    var body: some View {
        NavigationStack {
            Form {
                questionSections
                submitButtonSection
            }
            .navigationTitle("Task \(taskIdx)")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem {
                    dismissButton
                }
            }
            .interactiveDismissDisabled()
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
        AsyncButton(state: $viewState, action: handleSubmit) {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .padding(4)
        }
            .padding(.horizontal, -16)
            .buttonStyle(.borderedProminent)
            .disabled(!areAllQuestionsAnswered)
            .listRowBackground(Color.clear)
    }

    private var dismissButton: some View {
        Button {
            isPresented = false
        } label: {
            Label("Dismiss", systemImage: "xmark")
                .accessibilityLabel("Dismiss")
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

    private func handleSubmit() async {
        let answers = answerState.getAnswers(for: task.questions)
        await onSubmit(answers)
        isPresented = false
    }
}
