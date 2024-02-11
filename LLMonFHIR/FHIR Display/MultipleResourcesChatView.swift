//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziLLMOpenAI
import SpeziSpeechSynthesizer
import SpeziViews
import SwiftUI


struct MultipleResourcesChatView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Environment(FHIRMultipleResourceInterpreter.self) private var multipleResourceInterpreter
    
    @State private var speechSynthesizer = SpeechSynthesizer()
    @AppStorage(StorageKeys.enableTextToSpeech) private var textToSpeech = StorageKeys.Defaults.enableTextToSpeech
    
    
    var body: some View {
        @Bindable var multipleResourceInterpreter = multipleResourceInterpreter
        NavigationStack {
            Group {
                if let llm = multipleResourceInterpreter.llm {
                    let contextBinding = Binding { llm.context } set: { llm.context = $0 }
                    ChatView(
                        contextBinding,
                        disableInput: multipleResourceInterpreter.viewState == .processing
                    )
                        .onChange(of: llm.context) {
                            multipleResourceInterpreter.queryLLM()
                        }
                } else {
                    ChatView(
                        .constant([])
                    )
                }
            }
                .navigationTitle("LLM on FHIR")
                .toolbar {
                    toolbar
                }
                .viewStateAlert(state: $multipleResourceInterpreter.viewState)
                .onAppear {
                    multipleResourceInterpreter.queryLLM()
                }
        }
            .interactiveDismissDisabled()
    }
    
    
    @MainActor @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if multipleResourceInterpreter.viewState == .processing {
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
                    textToSpeech.toggle()
                },
                label: {
                    if textToSpeech {
                        Image(systemName: "speaker")
                            .accessibilityLabel(Text("Text to speech is enabled, press to disable text to speech."))
                    } else {
                        Image(systemName: "speaker.slash")
                            .accessibilityLabel(Text("Text to speech is disabled, press to enable text to speech."))
                    }
                }
            )
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
            .disabled(multipleResourceInterpreter.viewState == .processing)
        }
    }
}
