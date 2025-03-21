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
            disableInput: interpreter.llmSession.state.representation == .processing,
            exportFormat: .text,
            messagePendingAnimation: .automatic
        )
            .speak(interpreter.llmSession.context.chat, muted: !textToSpeech)
            .speechToolbarButton(muted: !$textToSpeech)
            .viewStateAlert(state: interpreter.llmSession.state)
            .onChange(of: interpreter.llmSession.context, initial: true) {
                if interpreter.shouldGenerateResponse {
                    interpreter.generateAssistantResponse()
                }
            }
    }

    @MainActor @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        let isProcessing = interpreter.llmSession.state.representation == .processing
        let isDisabled = isProcessing
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                interpreter.cancel()
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    interpreter.startNewConversation()
                },
                label: {
                    Image(systemName: "trash")
                        .accessibilityLabel(Text("Reset Chat"))
                }
            )
            .disabled(isDisabled)
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
