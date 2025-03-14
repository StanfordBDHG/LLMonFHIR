//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMLocalDownload
import SpeziLLMOpenAI
import SwiftUI


struct SettingsView: View {
    private enum SettingsDestinations {
        case openAIKey
        case openAIModel
        case openAIModelParameters
        case resourceSelection
        case promptSummary
        case promptInterpretation
        case promptMultipleResourceInterpretation
        case downloadLocalLLM
    }
    
    @State private var path = NavigationPath()
    @Environment(\.dismiss) private var dismiss
    @Environment(FHIRInterpretationModule.self) var fhirInterpretationModule
    
    @AppStorage(StorageKeys.enableTextToSpeech) private var enableTextToSpeech = StorageKeys.currentEnableTextToSpeech
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.currentResourceCountLimit
    @AppStorage(StorageKeys.openAIModel) private var openAIModel = StorageKeys.currentOpenAIModel
    @AppStorage(StorageKeys.isUsabilityStudyEnabled) private var enableUsabilityStudy = CommandLine.arguments.contains("--userStudy")
    
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                openAISettings
                speechSettings
                resourcesLimitSettings
                resourcesSettings
                promptsSettings
                usabilityStudySettings
            }
                .navigationTitle("SETTINGS_TITLE")
                .navigationDestination(for: SettingsDestinations.self) { destination in
                    Group {
                        settingsDestinationView(destination)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("SETTINGS_DONE") {
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
            } onEditingChanged: { complete in
                if complete {
                    fhirInterpretationModule.updateSchemas()
                }
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
            NavigationLink(value: SettingsDestinations.openAIModelParameters) {
                Text("SETTINGS_OPENAI_MODEL_PARAMETERS")
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
    
    private var usabilityStudySettings: some View {
        Section("Usability Study Settings") {
            Toggle(isOn: $enableUsabilityStudy) {
                Text("Enable Usability Study")
            }
        }
    }
    
    @ViewBuilder
    private func settingsDestinationView(_ destination: SettingsDestinations) -> some View {
        switch destination {
        case .openAIKey:
            LLMOpenAIAPITokenOnboardingStep(actionText: "OPEN_AI_KEY_SAVE_ACTION") {
                fhirInterpretationModule.updateSchemas()
                path.removeLast()
            }
        case .openAIModel:
            LLMOpenAIModelOnboardingStep(
                actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                models: [.gpt4o, .gpt4_turbo, .gpt3_5_turbo]
            ) { chosenModelType in
                openAIModel = chosenModelType
                fhirInterpretationModule.updateSchemas()
                path.removeLast()
            }
        case .openAIModelParameters:
            OpenAIModelParametersView()
        case .resourceSelection:
            ResourceSelection()
        case .promptSummary:
            FHIRPromptSettingsView(promptType: .summary) {
                fhirInterpretationModule.updateSchemas()
                path.removeLast()
            }
        case .promptInterpretation:
            FHIRPromptSettingsView(promptType: .interpretation) {
                fhirInterpretationModule.updateSchemas()
                path.removeLast()
            }
        case .promptMultipleResourceInterpretation:
            FHIRPromptSettingsView(promptType: .interpretMultipleResources) {
                fhirInterpretationModule.updateSchemas()
                path.removeLast()
            }
        case .downloadLocalLLM:
            LLMLocalDownloadView(
                model: .custom(id: "mlx-community/OpenHermes-2.5-Mistral-7B-4bit-mlx"),
                downloadDescription: "Download the LLM model to generate summaries of FHIR resources."
            ) {
                fhirInterpretationModule.updateSchemas()
                path.removeLast()
            }
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    SettingsView()
}
