//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI
import SpeziSpeechSynthesizer
import SpeziViews
import SwiftUI


struct MultipleResourcesChatView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: MultipleResourcesChatViewModel

    @AppStorage(StorageKeys.enableTextToSpeech) private var textToSpeech = StorageKeys.currentEnableTextToSpeech


    var body: some View {
        NavigationStack {
            chatView
                .navigationTitle(viewModel.navigationTitle)
                .toolbar { toolbarContent }
        }
            .interactiveDismissDisabled()
    }


    @ViewBuilder private var chatView: some View {
        VStack {
            MultipleResourcesChatViewProcessingView(viewModel: viewModel)
            ChatView(
                viewModel.chatBinding,
                disableInput: viewModel.isProcessing,
                exportFormat: .text,
                messagePendingAnimation: .manual(shouldDisplay: viewModel.showTypingIndicator)
            )
                .speak(viewModel.llmSession.context.chat, muted: !textToSpeech)
                .speechToolbarButton(muted: !$textToSpeech)
                .viewStateAlert(state: viewModel.llmSession.state)
                .onChange(of: viewModel.llmSession.context, initial: true) {
                    Task {
                        _ = await viewModel.generateAssistantResponse()
                    }
                }
        }
            .animation(.easeInOut(duration: 0.4), value: viewModel.isProcessing)
    }

    @MainActor @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                viewModel.dismiss(dismiss)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    viewModel.startNewConversation()
                },
                label: {
                    Image(systemName: "trash")
                        .accessibilityLabel(Text("Reset Chat"))
                }
            )
            .disabled(viewModel.isProcessing)
        }
    }


    /// Creates a ``MultipleResourcesChatView`` that displays a chat interface for interacting with FHIR resources.
    ///
    /// This initializer sets up the view with the provided interpreter, navigation title, and text-to-speech setting.
    /// It creates a view model that coordinates between the UI and the FHIR interpreter.
    ///
    /// - Parameters:
    ///   - interpreter: The FHIR resource interpreter that manages the LLM session and healthcare data
    ///   - navigationTitle: The title to display in the navigation bar
    ///   - textToSpeech: A binding to control whether spoken feedback is enabled
    init(interpreter: FHIRMultipleResourceInterpreter, navigationTitle: String) {
        viewModel = MultipleResourcesChatViewModel(
            interpreter: interpreter,
            navigationTitle: navigationTitle
        )
    }
}
