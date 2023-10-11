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
        case promptMultipleResourceInterpretation
    }
    
    @State private var path = NavigationPath()
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKeys.enableTextToSpeech) private var enableTextToSpeech = StorageKeys.Defaults.enableTextToSpeech
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.Defaults.resourceLimit
    
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                openAISettings
                speechSettings
                resourcesLimitSettings
                promptsSettings
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
    
    private var speechSettings: some View {
        Section("SETTINGS_SPEECH") {
            Toggle(isOn: $enableTextToSpeech) {
                Text("SETTINGS_SPEECH_TEXT_TO_SPEECH")
            }
        }
    }
    
    private var resourcesLimitSettings: some View {
        Section("SETTINGS_RESOURCES_LIMIT") {
            Stepper(value: $resourceLimit, in: 10...500, step: 10) {
                Text("RESOURCE_LIMIT_TEXT \(resourceLimit)")
            }
        }
    }
    
    private var openAISettings: some View {
        Section("SETTINGS_OPENAI") {
            NavigationLink(value: SettingsDestinations.openAIKey) {
                Text("SETTINGS_OPENAI_KEY")
            }
            NavigationLink(value: SettingsDestinations.openAIModel) {
                Text("SETTINGS_OPENAI_MODEL")
            }
        }
    }
    
    private var promptsSettings: some View {
        Section("SETTINGS_PROMPTS") {
            NavigationLink(value: SettingsDestinations.promptSummary) {
                Text("SETTINGS_PROMPTS_SUMMARY")
            }
            NavigationLink(value: SettingsDestinations.promptInterpretation) {
                Text("SETTINGS_PROMPTS_INTERPRETATION")
            }
            NavigationLink(value: SettingsDestinations.promptMultipleResourceInterpretation) {
                Text("SETTINGS_PROMPTS_INTERPRETATION_MULTIPLE_RESOURCES")
            }
        }
    }
    
    
    private func navigationDesination(for destination: SettingsDestinations) -> some View {
        Group {
            switch destination {
            case .openAIKey:
                OpenAIAPIKeyOnboardingStep(actionText: "OPEN_AI_KEY_SAVE_ACTION") {
                    path.removeLast()
                }
            case .openAIModel:
                OpenAIModelSelectionOnboardingStep(actionText: "OPEN_AI_MODEL_SAVE_ACTION", models: [Model.gpt4, Model.gpt3_5Turbo0613]) {
                    path.removeLast()
                }
            case .promptSummary:
                PromptSettingsView(promptType: .summary, path: $path)
            case .promptInterpretation:
                PromptSettingsView(promptType: .interpretation, path: $path)
            case .promptMultipleResourceInterpretation:
                PromptSettingsView(promptType: .interpretMultipleResources, path: $path)
            }
        }
    }
}
