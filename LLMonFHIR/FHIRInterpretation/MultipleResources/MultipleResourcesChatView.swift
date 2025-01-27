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
    @Environment(FHIRMultipleResourceInterpreter.self) private var multipleResourceInterpreter
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var textToSpeech: Bool
    private let navigationTitle: Text
    
    
    var body: some View {
        NavigationStack {
            chatView
                .navigationTitle(navigationTitle)
                .toolbar { toolbarContent }
                .task { await multipleResourceInterpreter.prepareLLM() }
        }
        .interactiveDismissDisabled()
    }
    
    
    @MainActor @ViewBuilder private var chatView: some View {
        if let llm = multipleResourceInterpreter.llm {
            ChatView(
                Binding(
                    get: { llm.context.chat },
                    set: { llm.context.chat = $0 }
                ),
                disableInput: llm.state.representation == .processing,
                messagePendingAnimation: .automatic
            )
            .speak(llm.context.chat, muted: !textToSpeech)
            .speechToolbarButton(muted: !$textToSpeech)
            .viewStateAlert(state: llm.state)
            .onChange(of: llm.context) {
                if llm.state != .generating {
                    multipleResourceInterpreter.queryLLM()
                }
            }
        } else {
            ProgressView()
        }
    }
    
    @MainActor @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        let isProcessing = multipleResourceInterpreter.llm?.state.representation == .processing
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
                multipleResourceInterpreter.llm?.cancel()
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    multipleResourceInterpreter.resetChat()
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
