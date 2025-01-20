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


public struct MultipleResourcesChatView: View {
    @Environment(FHIRMultipleResourceInterpreter.self) private var multipleResourceInterpreter
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var textToSpeech: Bool
    private let navigationTitle: Text
    
    
    public var body: some View {
        @Bindable var multipleResourceInterpreter = multipleResourceInterpreter
        NavigationStack {
            Group {
                if let llm = multipleResourceInterpreter.llm {
                    let contextBinding = Binding { llm.context.chat } set: { llm.context.chat = $0 }
                    
                    ChatView(
                        contextBinding,
                        disableInput: llm.state.representation == .processing
                    )
                        .speak(llm.context.chat, muted: !textToSpeech)
                        .speechToolbarButton(muted: !$textToSpeech)
                        .viewStateAlert(state: llm.state)
                        .onChange(of: llm.context, initial: true) { _, _ in
                            if llm.state != .generating {
                                multipleResourceInterpreter.queryLLM()
                            }
                        }
                } else {
                    ProgressView()
                }
            }
                .navigationTitle(navigationTitle)
                .toolbar {
                    toolbar
                }
                .task {
                    await multipleResourceInterpreter.prepareLLM()
                }
        }
            .interactiveDismissDisabled()
    }
    
    
    @MainActor @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if multipleResourceInterpreter.llm?.state.representation == .processing {
                ProgressView()
            } else {
                Button("Close") {
                    dismiss()
                }
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
            .disabled(multipleResourceInterpreter.llm?.state.representation == .processing)
        }
    }
    
    
    /// Creates a ``MultipleResourcesChatView`` displaying a Spezi `Chat` with all available FHIR resources via a Spezi LLM..
    ///
    /// - Parameters:
    ///    - navigationTitle: The localized title displayed for purposes of navigation.
    ///    - textToSpeech: Indicates if the output of the LLM is converted to speech and outputted to the user.
    public init(
        navigationTitle: LocalizedStringResource,
        textToSpeech: Binding<Bool>
    ) {
        self.navigationTitle = Text(navigationTitle)
        self._textToSpeech = textToSpeech
    }
    
    /// Creates a ``MultipleResourcesChatView`` displaying a Spezi `Chat` with all available FHIR resources via a Spezi LLM..
    ///
    /// - Parameters:
    ///    - navigationTitle: The title displayed for purposes of navigation.
    ///    - textToSpeech: Indicates if the output of the LLM is converted to speech and outputted to the user.
    @_disfavoredOverload
    public init<Title: StringProtocol>(
        navigationTitle: Title,
        textToSpeech: Binding<Bool>
    ) {
        self.navigationTitle = Text(verbatim: String(navigationTitle))
        self._textToSpeech = textToSpeech
    }
}
