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
        @Bindable var viewModel = viewModel
        NavigationStack { // swiftlint:disable:this closure_body_length
            chatView
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.isTaskInstructionsSheetPresented = true
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityHidden(true)
                        }
                        .disabled(viewModel.isTaskIntructionButtonDisabled)
                    }
                }
                .sheet(isPresented: $viewModel.isSurveyViewPresented) {
                    surveySheet()
                }
                .sheet(isPresented: $viewModel.isTaskInstructionsSheetPresented) {
                    taskInstructionSheet()
                }
                .viewStateAlert(state: viewModel.llmSession.state)
                .onAppear(perform: viewModel.startSurvey)
                .onChange(of: viewModel.llmSession.context, initial: true) {
                    Task {
                        _ = await viewModel.generateAssistantResponse()
                    }
                }
        }
    }
    
    
    @ViewBuilder private var chatView: some View {
        VStack {
            MultipleResourcesChatViewProcessingView(viewModel: viewModel)
            ChatView(
                viewModel.chatBinding,
                disableInput: viewModel.shouldDisableChatInput,
                speechToText: false,
                messagePendingAnimation: .manual(shouldDisplay: viewModel.showTypingIndicator)
            )
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isProcessing)
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
        study: Study,
        interpreter: FHIRMultipleResourceInterpreter,
        resourceSummary: FHIRResourceSummary
    ) {
        viewModel = UserStudyChatViewModel(
            study: study,
            interpreter: interpreter,
            resourceSummary: resourceSummary
        )
    }
    
    
    @ViewBuilder
    private func surveySheet() -> some View {
        @Bindable var viewModel = viewModel
        if let task = viewModel.currentTask, let taskIdx = viewModel.userDisplayableCurrentTaskIdx {
            SurveyView(
                task: task,
                taskIdx: taskIdx,
                isPresented: $viewModel.isSurveyViewPresented
            ) { answers in
                do {
                    try await viewModel.submitSurveyAnswers(answers)
                } catch {
                    print("Error submitting answers: \(error)")
                }
            }
            .presentationDetents([.large])
        }
    }
    
    @ViewBuilder
    private func taskInstructionSheet() -> some View {
        if let task = viewModel.currentTask, let taskIdx = viewModel.userDisplayableCurrentTaskIdx {
            TaskInstructionView(
                task: task,
                taskIdx: taskIdx,
                isPresented: $viewModel.isTaskInstructionsSheetPresented
            )
        }
    }
}
