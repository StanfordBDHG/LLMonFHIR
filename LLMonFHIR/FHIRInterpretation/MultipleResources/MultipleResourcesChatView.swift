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
                .task { await interpreter.prepareLLM() }
        }
        .interactiveDismissDisabled()
    }
    
    
    @MainActor @ViewBuilder private var chatView: some View {
        ChatView(
            Binding(
                get: { interpreter.llm.context.chat },
                set: { interpreter.llm.context.chat = $0 }
            ),
            disableInput: interpreter.llm.state.representation == .processing,
            exportFormat: .text,
            messagePendingAnimation: .manual(shouldDisplay: interpreter.viewState == .processing)
        )
            .speak(interpreter.llm.context.chat, muted: !textToSpeech)
            .speechToolbarButton(muted: !$textToSpeech)
            .viewStateAlert(state: interpreter.llm.state)
            .onChange(of: interpreter.llm.context, initial: true) {
                if interpreter.llm.state != .generating && interpreter.llm.context.chat.last?.role == .user {
                    interpreter.queryLLM()
                }
            }
            .onAppear {
                guard !interpreter.llm.context.chat.contains(where: { $0.role == .user }) else {
                    return
                }
                interpreter.viewState = .processing
                interpreter.queryLLM()
            }
    }
    
    @MainActor @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        let isProcessing = interpreter.llm.state.representation == .processing
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                interpreter.llm.cancel()
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    interpreter.resetChat()
                    interpreter.queryLLM()
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
