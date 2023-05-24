//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOpenAI
import SwiftUI


struct SettingsView: View {
    private enum SettingsDestinations {
        case openAIKey
        case openAIModel
        case promptSummary
        case promptInterpretation
    }
    
    @State private var path = NavigationPath()
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("SETTINGS_OPENAI") {
                    NavigationLink(value: SettingsDestinations.openAIKey) {
                        Text("SETTINGS_OPENAI_KEY")
                    }
                    NavigationLink(value: SettingsDestinations.openAIModel) {
                        Text("SETTINGS_OPENAI_MODEL")
                    }
                }
                Section("SETTINGS_PROMPTS") {
                    NavigationLink(value: SettingsDestinations.promptSummary) {
                        Text("SETTINGS_PROMPTS_SUMMARY")
                    }
                    NavigationLink(value: SettingsDestinations.promptInterpretation) {
                        Text("SETTINGS_PROMPTS_INTERPRETATION")
                    }
                }
            }
                .navigationTitle("SETTINGS_TITLE")
                .navigationDestination(for: SettingsDestinations.self) { destination in
                    navigationDesination(for: destination)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("FHIR_RESOURCES_CHAT_CANCEL") {
                            dismiss()
                        }
                    }
                }
        }
    }
    
    
    private func navigationDesination(for destination: SettingsDestinations) -> some View {
        Group {
            switch destination {
            case .openAIKey:
                OpenAIAPIKeyOnboardingStep<FHIR>(actionText: String(localized: "OPEN_AI_KEY_SAVE_ACTION")) {
                    path.removeLast()
                }
            case .openAIModel:
                OpenAIModelSelectionOnboardingStep<FHIR>(actionText: String(localized: "OPEN_AI_MODEL_SAVE_ACTION")) {
                    path.removeLast()
                }
            case .promptSummary:
                PromptSettingsView(promptType: .summary, path: $path)
            case .promptInterpretation:
                PromptSettingsView(promptType: .interpretation, path: $path)
            }
        }
    }
}
