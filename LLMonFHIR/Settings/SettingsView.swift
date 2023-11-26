//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIRInterpretation
import SpeziOpenAI
import SwiftUI


struct SettingsView: View {
    private enum SettingsDestinations {
        case openAIKey
        case openAIModel
        case resourceSelection
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
                resourcesSettings
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
        Section("Resource Limit") {
            Stepper(value: $resourceLimit, in: 10...2000, step: 10) {
                Text("Resource Limit \(resourceLimit)")
            }
        }
    }
    
    private var resourcesSettings: some View {
        Section("Resource Selection") {
            NavigationLink(value: SettingsDestinations.resourceSelection) {
                Text("Resource Selection")
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
                OpenAIModelSelectionOnboardingStep(
                    actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                    models: [Model.gpt4, Model.gpt4_1106_preview]
                ) {
                    path.removeLast()
                }
            case .resourceSelection:
                ResourceSelection()
            case .promptSummary:
                FHIRPromptSettingsView(promptType: .summary) {
                    path.removeLast()
                }
            case .promptInterpretation:
                FHIRPromptSettingsView(promptType: .interpretation) {
                    path.removeLast()
                }
            case .promptMultipleResourceInterpretation:
                FHIRPromptSettingsView(promptType: .interpretMultipleResources) {
                    path.removeLast()
                }
            }
        }
    }
}
