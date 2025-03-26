//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SwiftUI

struct UserStudyChatView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: UserStudyChatViewModel


    var body: some View {
        NavigationStack {
            chatContent
                .navigationTitle(viewModel.navigationState.title)
                .toolbar {
                    UserStudyChatToolbar(
                        viewModel: viewModel,
                        isInputDisabled: viewModel.isProcessing,
                        onDismiss: {
                            viewModel.handleDismiss(dismiss: dismiss)
                        }
                    )
                }
                .onAppear(perform: handleAppear)
                .sheet(
                    isPresented: $viewModel.isSurveyViewPresented,
                    content: surveySheet
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }


    @ViewBuilder private var chatContent: some View {
        ChatView(
            viewModel.chatBinding,
            disableInput: viewModel.isProcessing,
            speechToText: false,
            exportFormat: viewModel.navigationState == .completed ? .text : nil,
            messagePendingAnimation: .manual(shouldDisplay: viewModel.showTypingIndicator)
        )
            .viewStateAlert(state: viewModel.llmSession.state)
            .onChange(of: viewModel.llmSession.context, initial: true) {
                viewModel.generateAssistantResponse()
            }
    }

    /// Creates a new user study chat view
    ///
    /// This initializer sets up a view for conducting a structured study with
    /// chat-based interactions and survey tasks.
    ///
    /// - Parameter survey: The survey configuration that defines the study's tasks and structure
    init(survey: Survey, interpreter: FHIRMultipleResourceInterpreter) {
        viewModel = UserStudyChatViewModel(
            survey: survey,
            interpreter: interpreter
        )
    }


    @ViewBuilder
    private func surveySheet() -> some View {
        if let task = viewModel.getCurrentTask() {
            SurveyView(
                task: task,
                isPresented: $viewModel.isSurveyViewPresented
            ) { answers in
                do {
                    try viewModel.submitSurveyAnswers(answers)
                } catch {
                    print("Error submitting answers: \(error)")
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func handleAppear() {
        viewModel.startSurvey()
    }
}
