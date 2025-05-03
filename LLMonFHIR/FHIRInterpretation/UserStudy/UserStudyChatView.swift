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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    UserStudyChatToolbar(
                        viewModel: viewModel,
                        isInputDisabled: viewModel.shouldDisableToolbarInput,
                        onDismiss: {
                            viewModel.handleDismiss(dismiss: dismiss)
                        }
                    )
                }
                .sheet(
                    isPresented: makeBinding(
                        get: { viewModel.isSurveyViewPresented },
                        set: { viewModel.setSurveyViewPresented($0) }
                    ),
                    content: surveySheet
                )
                .sheet(
                    isPresented: makeBinding(
                        get: { viewModel.isTaskIntructionAlertPresented },
                        set: { if !$0 { viewModel.dismissTaskInstructionAlert() } }
                    ),
                    content: taskInstructionSheet
                )
                .onAppear(perform: viewModel.startSurvey)
                .onChange(of: viewModel.llmSession.context, initial: true) {
                    Task {
                        _ = await viewModel.generateAssistantResponse()
                    }
                }
        }
    }


    @ViewBuilder private var chatContent: some View {
        ChatView(
            viewModel.chatBinding,
            disableInput: viewModel.shouldDisableChatInput,
            speechToText: false,
            messagePendingAnimation: .manual(shouldDisplay: viewModel.showTypingIndicator)
        )
            .viewStateAlert(state: viewModel.llmSession.state)
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
                isPresented: makeBinding(
                    get: { viewModel.isSurveyViewPresented },
                    set: { viewModel.setSurveyViewPresented($0) }
                )
            ) { answers in
                do {
                    try viewModel.submitSurveyAnswers(answers)
                } catch {
                    print("Error submitting answers: \(error)")
                }
            }
            .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private func taskInstructionSheet() -> some View {
        if let currentTask = viewModel.currentTask {
            TaskInstructionView(
                task: currentTask,
                isPresented: makeBinding(
                    get: { viewModel.isTaskIntructionAlertPresented },
                    set: { if !$0 { viewModel.dismissTaskInstructionAlert() } }
                )
            )
            .presentationDetents([.medium])
        }
    }
}

func makeBinding<T>(
    get: @escaping () -> T,
    set: @escaping (T) -> Void
) -> Binding<T> {
    Binding(
        get: get,
        set: set
    )
}
