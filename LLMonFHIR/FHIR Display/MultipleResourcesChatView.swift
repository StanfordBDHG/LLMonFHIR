//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziOpenAI
import SpeziSpeechSynthesizer
import SpeziViews
import SwiftUI


struct MultipleResourcesChatView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Environment(FHIRMultipleResourceInterpreter.self) private var multipleResourceInterpreter
    
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    @AppStorage(StorageKeys.enableTextToSpeech) private var textToSpeech = StorageKeys.Defaults.enableTextToSpeech
    
    
    private var disableInput: Binding<Bool> {
        Binding(
            get: {
                multipleResourceInterpreter.viewState == .processing
            },
            set: { _ in }
        )
    }
    
    var body: some View {
        @Bindable var multipleResourceInterpreter = multipleResourceInterpreter
        NavigationStack {
            ChatView($multipleResourceInterpreter.chat, disableInput: disableInput)
                .navigationTitle("LLM on FHIR")
                .toolbar {
                    toolbar
                }
                .viewStateAlert(state: $multipleResourceInterpreter.viewState)
                .onChange(of: multipleResourceInterpreter.chat) {
                    multipleResourceInterpreter.queryLLM()
                }
                .onAppear {
                    multipleResourceInterpreter.queryLLM()
                }
        }
            .interactiveDismissDisabled()
    }
    
    
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
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
