//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SpeziViews
import SwiftUI


/// Customize LLM ``FHIRPrompt``s.
///
/// Allows users to edit and save a prompt associated with a specific ``FHIRPrompt`` type, including where to insert FHIR resources dynamically in the prompt.
struct FHIRPromptCustomizationView: View {
    private let title: LocalizedStringResource
    private let promptDefinition: FHIRPrompt
    private let onSave: () async -> Void
    @State private var promptText: String = ""
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Customize prompt: \(title)")
                .multilineTextAlignment(.leading)
            TextEditor(text: $promptText)
                .fontDesign(.monospaced)
            Text("Place \(FHIRPrompt.fhirResourcePlaceholder) at the position in the prompt where the FHIR resource should be inserted. Optionally place \(FHIRPrompt.localePlaceholder) where you would like to insert the current locale.")
                .multilineTextAlignment(.leading)
                .font(.caption)
            AsyncButton(state: $viewState) {
                promptDefinition.save(prompt: promptText)
                await onSave()
            } label: {
                Text("Save Prompt")
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Initializes a new `PromptSettingsView` with the specified ``FHIRPrompt`` and a save action.
    /// - Parameters:
    ///   - promptType: The ``FHIRPrompt`` instance whose settings are being modified. It holds the information about the specific prompt being edited.
    ///   - onSave: A closure to be called when the user saves the prompt. This allows for custom actions, like dismissing the view.
    init(_ title: LocalizedStringResource, prompt promptDefinition: FHIRPrompt, onSave: @escaping () async -> Void) {
        self.title = title
        self.promptDefinition = promptDefinition
        self.onSave = onSave
        self._promptText = State(initialValue: promptDefinition.promptText)
    }
}
