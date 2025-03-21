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
    @Environment(FHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(\.dismiss) private var dismiss

    // Track if reset button was recently tapped
    @State private var isResetting = false

    @Binding private var textToSpeech: Bool
    private let navigationTitle: Text


    var body: some View {
        NavigationStack {
            chatView
                .navigationTitle(navigationTitle)
                .toolbar { toolbarContent }
        }
        .interactiveDismissDisabled()
    }


    @ViewBuilder private var chatView: some View {
        ChatView(
            interpreter.chatBinding,
            disableInput: interpreter.llmSession.state.representation == .processing || isResetting,
            exportFormat: .text,
            messagePendingAnimation: .automatic
        )
            .speak(interpreter.llmSession.context.chat, muted: !textToSpeech)
            .speechToolbarButton(muted: !$textToSpeech)
            .viewStateAlert(state: interpreter.llmSession.state)
            .onChange(of: interpreter.llmSession.context, initial: true) {
                if interpreter.llmSession.state != .generating &&
                   interpreter.llmSession.context.last?.role != .system &&
                   !isResetting {
                    interpreter.generateAssistantResponse()
                }
            }
            .overlay {
                if isResetting {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
    }

    @MainActor @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        let isProcessing = interpreter.llmSession.state.representation == .processing || isResetting
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                interpreter.cancel()
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    isResetting = true
                    interpreter.startNewConversation()
                    Task {
                        try? await Task.sleep(for: .seconds(5))
                        interpreter.generateAssistantResponse()
                        try? await Task.sleep(for: .seconds(5))
                        isResetting = false
                    }
                },
                label: {
                    Image(systemName: "trash")
                        .accessibilityLabel(Text("Reset Chat"))
                }
            )
            .disabled(isProcessing)
        }
    }


    /// Creates a ``MultipleResourcesChatView`` displaying a Spezi `Chat` with all available FHIR resources via a Spezi LLM..
    ///
    /// - Parameters:
    ///    - navigationTitle: The localized title displayed for purposes of navigation.
    ///    - textToSpeech: Indicates if the output of the LLM is converted to speech and outputted to the user.
    init(
        navigationTitle: LocalizedStringResource,
        textToSpeech: Binding<Bool>
    ) {
        self.navigationTitle = Text(navigationTitle)
        self._textToSpeech = textToSpeech
    }
}
