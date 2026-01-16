//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziLLM
import SpeziViews
import SwiftUI

struct UserStudyChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: UserStudyChatViewModel
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        @Bindable var model = model
        NavigationStack { // swiftlint:disable:this closure_body_length
            chatView
                .navigationTitle(model.navigationState.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    UserStudyChatToolbar(
                        model: model,
                        isInputDisabled: model.shouldDisableToolbarInput,
                        onDismiss: {
                            model.handleDismiss(dismiss: dismiss)
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            model.presentedSheet = .instructions
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityHidden(true)
                        }
                        .disabled(model.isTaskIntructionButtonDisabled)
                    }
                }
                .sheet(item: $model.presentedSheet) { sheet in
                    switch sheet {
                    case .instructions:
                        taskInstructionSheet()
                    case .survey:
                        surveySheet()
                    case .uploadingReport:
                        uploadSheet()
                    }
                }
                .onChange(of: model.llmSession.state, initial: true) { _, newState in
                    switch newState {
                    case .error(let error):
                        Task {
                            try await Task.sleep(for: .seconds(0.5))
                            model.presentedSheet = nil
                            try await Task.sleep(for: .seconds(0.5))
                            viewState = .error(AnyLocalizedError(error: error))
                        }
                    default:
                        viewState = .idle
                    }
                }
                .viewStateAlert(state: $viewState)
                .onAppear(perform: model.startSurvey)
                .onChange(of: model.llmSession.context, initial: true) {
                    Task {
                        _ = await model.generateAssistantResponse()
                    }
                }
        }
    }
    
    
    @ViewBuilder private var chatView: some View {
        VStack {
            MultipleResourcesChatViewProcessingView(model: model)
            ChatView(
                model.chatBinding,
                disableInput: model.shouldDisableChatInput,
                speechToText: false,
                messagePendingAnimation: .manual(shouldDisplay: model.showTypingIndicator)
            )
        }
        .animation(.easeInOut(duration: 0.4), value: model.isProcessing)
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
        resourceSummary: FHIRResourceSummary,
        uploader: FirebaseUpload?
    ) {
        model = UserStudyChatViewModel(
            study: study,
            interpreter: interpreter,
            resourceSummary: resourceSummary,
            uploader: uploader
        )
    }
    
    
    @ViewBuilder
    private func surveySheet() -> some View {
        if let task = model.currentTask, let taskIdx = model.userDisplayableCurrentTaskIdx {
            SurveyView(task: task, taskIdx: taskIdx) { answers in
                do {
                    try model.submitSurveyAnswers(answers)
                } catch {
                    print("Error submitting answers: \(error)")
                }
            } onDismiss: {
                model.presentedSheet = nil
            }
            .presentationDetents([.large])
        }
    }
    
    @ViewBuilder
    private func taskInstructionSheet() -> some View {
        if let task = model.currentTask, let taskIdx = model.userDisplayableCurrentTaskIdx {
            TaskInstructionView(task: task, userDisplayableCurrentTaskIdx: taskIdx) {
                model.presentedSheet = nil
            }
        }
    }
    
    @ViewBuilder
    private func uploadSheet() -> some View {
        BottomSheet {
            ProgressView("Submitting Results...")
                .progressViewStyle(.circular)
                .padding()
                .interactiveDismissDisabled()
        }
    }
}
