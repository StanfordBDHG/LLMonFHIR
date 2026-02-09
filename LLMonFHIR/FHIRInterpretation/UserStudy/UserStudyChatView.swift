//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SpeziChat
import SpeziFoundation
import SpeziLLM
import SpeziViews
import SwiftUI


struct UserStudyChatView: View {
    @Environment(\.dismiss) private var dismiss
    
    @LocalPreference(.enableTextToSpeech) private var enableTextToSpeechPrefValue
    
    private let model: UserStudyChatViewModel
    @State private var viewState: ViewState = .idle
    
    private var enableTextToSpeech: Binding<Bool> {
        Binding<Bool> { [weak model] in
            guard let model else {
                return false
            }
            return model.study.isUnguided ? enableTextToSpeechPrefValue : false
        } set: { newValue in
            enableTextToSpeechPrefValue = newValue
        }
    }
    
    var body: some View {
        @Bindable var model = model
        NavigationStack { // swiftlint:disable:this closure_body_length
            chatView
                .applyTitleConfig(model.navigationState.titleConfig(in: model.study))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    UserStudyChatToolbar(
                        model: model,
                        isTextToSpeechEnabled: enableTextToSpeech,
                        onDismiss: {
                            model.handleDismiss(dismiss: dismiss)
                        }
                    )
                }
                .sheet(item: $model.presentedSheet) { sheet in
                    switch sheet {
                    case .instructions:
                        taskInstructionSheet()
                    case .survey:
                        SurveySheet(model: model)
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
                .onAppear {
                    model.didUploadHandler = {
                        dismiss()
                    }
                    model.startSurvey()
                }
                .onChange(of: model.llmSession.context, initial: true) {
                    Task {
                        _ = await model.generateAssistantResponse()
                    }
                }
        }
    }
    
    @ViewBuilder private var chatView: some View {
        VStack {
            UserStudyChatProcessingView(model: model)
            ChatView(
                model.chatBinding,
                disableInput: !model.shouldEnableChatInput,
                speechToText: model.study.isUnguided,
                messagePendingAnimation: .manual(shouldDisplay: model.showTypingIndicator)
            )
            .speak(model.llmSession.context.chat, muted: !enableTextToSpeech.wrappedValue)
        }
        .animation(.easeInOut(duration: 0.4), value: model.isProcessing)
    }
    
    init(model: UserStudyChatViewModel) {
        self.model = model
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


extension View {
    @ViewBuilder
    func applyTitleConfig(_ config: UserStudyChatViewModel.NavigationState.TitleConfig) -> some View {
        if #available(iOS 26, *), let subtitle = config.subtitle {
            self.navigationTitle(config.title)
                .navigationSubtitle(subtitle)
        } else {
            self.navigationTitle(config.title)
        }
    }
}
