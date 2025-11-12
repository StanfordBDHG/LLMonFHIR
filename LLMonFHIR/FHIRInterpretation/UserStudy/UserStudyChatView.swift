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
                            viewModel.setTaskInstructionSheetPresented(true)
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityHidden(true)
                        }
                        .disabled(viewModel.isTaskIntructionButtonDisabled)
                    }
                }
                .sheet(
                    isPresented: Binding<Bool>(
                        get: { viewModel.isSurveyViewPresented },
                        set: { viewModel.setSurveyViewPresented($0) }
                    ),
                    content: surveySheet
                )
                .sheet(
                    isPresented: Binding<Bool>(
                        get: { viewModel.isTaskIntructionAlertPresented },
                        set: { viewModel.setTaskInstructionSheetPresented($0) }
                    ),
                    content: taskInstructionSheet
                )
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
                isPresented: Binding<Bool>(
                    get: { viewModel.isSurveyViewPresented },
                    set: { viewModel.setSurveyViewPresented($0) }
                )
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
        if let currentTask = viewModel.currentTask {
            TaskInstructionView(
                task: currentTask,
                isPresented: Binding<Bool>(
                    get: { viewModel.isTaskIntructionAlertPresented },
                    set: { viewModel.setTaskInstructionSheetPresented($0) }
                )
            )
        }
    }
}
