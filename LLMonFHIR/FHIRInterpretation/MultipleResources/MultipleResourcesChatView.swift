//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziFHIR
import SpeziFoundation
import SpeziLLM
import SpeziLLMOpenAI
import SpeziSpeechSynthesizer
import SpeziViews
import SwiftUI


struct MultipleResourcesChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: MultipleResourcesChatViewModel
    @LocalPreference(.enableTextToSpeech) private var textToSpeech
    
    var body: some View {
        NavigationStack {
            chatView
                .navigationTitle(model.navigationTitle)
                .toolbar { toolbarContent }
        }
        .interactiveDismissDisabled()
    }
    
    private var chatView: some View {
        VStack {
            MultipleResourcesChatViewProcessingView(model: model)
            ChatView(
                model.chatBinding,
                disableInput: model.isProcessing,
                exportFormat: .text,
                messagePendingAnimation: .manual(shouldDisplay: model.showTypingIndicator)
            )
            .speak(model.llmSession.context.chat, muted: !textToSpeech)
            .speechToolbarButton(muted: !$textToSpeech)
            .viewStateAlert(state: model.llmSession.state)
            .onChange(of: model.llmSession.context, initial: true) {
                Task {
                    _ = await model.generateAssistantResponse()
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: model.isProcessing)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button {
                model.dismiss(dismiss)
            } label: {
                Label("Dismiss", systemImage: "xmark")
                    .accessibilityLabel("Dismiss")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                model.startNewConversation(for: nil)
            } label: {
                Image(systemName: "trash")
                    .accessibilityLabel(Text("Reset Chat"))
            }
            .disabled(model.isProcessing)
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
        model = MultipleResourcesChatViewModel(
            interpreter: interpreter,
            navigationTitle: navigationTitle
        )
    }
}
