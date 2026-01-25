//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import LLMonFHIRShared
import SpeziViews
import SwiftUI


struct SurveySheet: View {
    private var model: UserStudyChatViewModel
    private let firstTaskIdxWithQuestions: Int?
    @State private var path: [Int] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if let idx = firstTaskIdxWithQuestions {
                    view(for: idx)
                } else {
                    EmptyView()
                }
            }
            .navigationDestination(for: Int.self) { taskIdx in
                view(for: taskIdx)
            }
            .onChange(of: model.currentTaskIdx, initial: true) { _, newValue in
                guard let newValue, model.presentedSheet == .survey else {
                    // don't update the path if we're not presented.
                    // otherwise, the sheet will navigate forward as it is being dismissed, which looks weird.
                    return
                }
                // update the path to contain all task indices with questions,
                // in the range of 1 after the initial task with a question (which is handled separately above) and the current task.
                path = Array((0...newValue).filter { !model.study.tasks[$0].questions.isEmpty }.dropFirst())
            }
        }
    }
    
    init(model: UserStudyChatViewModel) {
        self.model = model
        self.firstTaskIdxWithQuestions = model.study.tasks.firstIndex { !$0.questions.isEmpty }
    }
    
    @ViewBuilder
    private func view(for taskIdx: Int) -> some View {
        let task = model.study.tasks[taskIdx]
        SurveyView(task: task, userDisplayableTaskIdx: taskIdx + 1) { answers in
            do {
                try model.submitSurveyAnswers(answers, for: task)
            } catch {
                print("Error submitting answers: \(error)")
            }
        } onDismiss: {
            model.presentedSheet = nil
        }
        .presentationDetents([.large])
        .navigationBarBackButtonHidden()
    }
}


// MARK: Survey View

/// The main view for displaying and collecting survey responses
private struct SurveyView: View {
    /// The task containing the questions to display
    let task: Study.Task
    /// The task's index within its containing survey, in a user-displayable format.
    let userDisplayableTaskIdx: Int
    /// Callback to invoke when the survey is submitted
    let onSubmit: @MainActor ([Study.Task.Question.Answer]) async -> Void
    /// Called when the sheet should be dismissed
    let onDismiss: @MainActor () -> Void
    
    /// The state object managing all answers
    @State private var answerState = SurveyAnswerState()
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        Form {
            questionSections
            submitButtonSection
        }
        .navigationTitle("Task \(userDisplayableTaskIdx)")
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar { toolbar }
        .interactiveDismissDisabled()
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
    
    private var toolbar: some ToolbarContent {
        ToolbarItem {
            if #available(iOS 26, *) {
                Button(role: .close) {
                    onDismiss()
                }
            } else {
                Button {
                    onDismiss()
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                        .accessibilityLabel("Dismiss")
                }
            }
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
        onDismiss()
        let answers = answerState.getAnswers(for: task.questions)
        await onSubmit(answers)
    }
}
