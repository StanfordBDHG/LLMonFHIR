//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Customize LLM ``FHIRPrompt``s.
///
/// Allows users to edit and save a prompt associated with a specific ``FHIRPrompt`` type, including where to insert FHIR resources dynamically in the prompt.
public struct FHIRPromptSettingsView: View {
    private let promptType: FHIRPrompt
    private let onSave: () -> Void
    @State private var prompt: String = ""
    
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Customize the \(promptType.localizedDescription.lowercased()).")
                .multilineTextAlignment(.leading)
            TextEditor(text: $prompt)
                .fontDesign(.monospaced)
            Text("Place \(FHIRPrompt.fhirResourcePlaceholder) at the position in the prompt where the FHIR resource should be inserted. Optionally place \(FHIRPrompt.localePlaceholder) where you would like to insert the current locale.")
                .multilineTextAlignment(.leading)
                .font(.caption)
            Button(
                action: {
                    promptType.save(prompt: prompt)
                    onSave()
                },
                label: {
                    Text("Save Prompt")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
            )
            .buttonStyle(.borderedProminent)
        }
            .padding()
            .navigationTitle(promptType.localizedDescription)
    }
    
    
    /// Initializes a new `PromptSettingsView` with the specified ``FHIRPrompt`` and a save action.
    /// - Parameters:
    ///   - promptType: The ``FHIRPrompt`` instance whose settings are being modified. It holds the information about the specific prompt being edited.
    ///   - onSave: A closure to be called when the user saves the prompt. This allows for custom actions, like dismissing the view.
    public init(promptType: FHIRPrompt, onSave: @escaping () -> Void) {
        self.promptType = promptType
        self.onSave = onSave
        self._prompt = State(initialValue: promptType.prompt)
    }
}
