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
                .alert(
                    "Instruction",
                    isPresented: $viewModel.isTaskIntructionAlertPresented,
                    actions: {
                        Button("Ok", role: .cancel) {
                            viewModel.isTaskIntructionAlertPresented = false
                        }
                    },
                    message: {
                        if let currentTask = viewModel.currentTask, let instruction = currentTask.instruction {
                            Text(instruction)
                        }
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }


    @ViewBuilder private var chatContent: some View {
        ChatView(
            viewModel.chatBinding,
            disableInput: viewModel.isProcessing,
            speechToText: false,
            messagePendingAnimation: .manual(shouldDisplay: viewModel.showTypingIndicator)
        )
            .viewStateAlert(state: viewModel.llmSession.state)
            .onChange(of: viewModel.llmSession.context, initial: true) {
                Task {
                    guard let response = await viewModel.generateAssistantResponse() else {
                        return
                    }
                    print("Assistant Response:", response)
                }
            }
    }


    /// Creates a new user study chat view
    ///
    /// This initializer sets up a view for conducting a structured study with
    /// chat-based interactions and survey tasks.
    ///
    /// - Parameters:
    ///   - survey: The survey configuration to use for this study
    ///   - interpreter: The FHIR interpreter to use for chat functionality
    ///   - resourceSummary: The FHIR resource summary provider for generating summaries of FHIR resources
    init(
        survey: Survey,
        interpreter: FHIRMultipleResourceInterpreter,
        resourceSummary: FHIRResourceSummary
    ) {
        viewModel = UserStudyChatViewModel(
            survey: survey,
            interpreter: interpreter,
            resourceSummary: resourceSummary
        )
    }


    @ViewBuilder
    private func surveySheet() -> some View {
        if let task = viewModel.currentTask {
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
