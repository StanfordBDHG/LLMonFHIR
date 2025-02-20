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
        case openAIModelSummary
        case openAIModelInterpretation
        case openAIModelMultipleInterpretation
        case resourceSelection
        case promptSummary
        case promptInterpretation
        case promptMultipleResourceInterpretation
        case downloadLocalLLM
    }
    
    @State private var path = NavigationPath()
    @Environment(\.dismiss) private var dismiss
    @Environment(FHIRResourceSummary.self) var resourceSummary
    @Environment(FHIRResourceInterpreter.self) var resourceInterpreter
    @Environment(FHIRMultipleResourceInterpreter.self) var multipleResourceInterpreter
    
    @AppStorage(StorageKeys.enableTextToSpeech) private var enableTextToSpeech = StorageKeys.Defaults.enableTextToSpeech
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.Defaults.resourceLimit
    @AppStorage(StorageKeys.allowedResourcesFunctionCallIdentifiers) private var allowedResourceIdentifiers = [String]()
    @AppStorage(StorageKeys.openAIModelSummarization) private var openAIModelSummarization = StorageKeys.Defaults.openAIModel
    @AppStorage(StorageKeys.openAIModelInterpretation) private var openAIModelInterpretation = StorageKeys.Defaults.openAIModel
    @AppStorage(StorageKeys.openAIModelMultipleInterpretation) private var openAIModelMultipleInterpretation =
    StorageKeys.Defaults.openAIModel
    
    
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
                    multipleResourceInterpreter.changeLLMSchema(
                        openAIModel: openAIModelMultipleInterpretation,
                        resourceCountLimit: resourceLimit,
                        resourceSummary: resourceSummary,
                        allowedResourcesFunctionCallIdentifiers: Set(allowedResourceIdentifiers)
                    )
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
            NavigationLink(value: SettingsDestinations.openAIModelSummary) {
                Text("SETTINGS_OPENAI_MODEL_SUMMARY")
            }
            NavigationLink(value: SettingsDestinations.openAIModelInterpretation) {
                Text("SETTINGS_OPENAI_MODEL_INTERPRETATION")
            }
            NavigationLink(value: SettingsDestinations.openAIModelMultipleInterpretation) {
                Text("SETTINGS_OPENAI_MODEL_MULTIPLE_RESOURCE_INTERPRETATION")
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
    
    @ViewBuilder
    private func settingsDestinationView(_ destination: SettingsDestinations) -> some View { // swiftlint:disable:this function_body_length
        switch destination {
        case .openAIKey:
            LLMOpenAIAPITokenOnboardingStep(actionText: "OPEN_AI_KEY_SAVE_ACTION") {
                path.removeLast()
            }
        case .openAIModelSummary:
            LLMOpenAIModelOnboardingStep(
                actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                models: [.gpt4o, .gpt4_turbo, .gpt3_5_turbo]
            ) { chosenModelType in
                openAIModelSummarization = chosenModelType
                resourceSummary.changeLLMSchema(
                    to: LLMOpenAISchema(
                        parameters: .init(
                            modelType: chosenModelType.rawValue,
                            systemPrompts: []
                        )
                    )
                )
                path.removeLast()
            }
        case .openAIModelInterpretation:
            LLMOpenAIModelOnboardingStep(
                actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                models: [.gpt4o, .gpt4_turbo, .gpt3_5_turbo]
            ) { chosenModelType in
                openAIModelInterpretation = chosenModelType
                resourceInterpreter.changeLLMSchema(
                    to: LLMOpenAISchema(
                        parameters: .init(
                            modelType: chosenModelType.rawValue,
                            systemPrompts: []
                        )
                    )
                )
                path.removeLast()
            }
        case .openAIModelMultipleInterpretation:
            LLMOpenAIModelOnboardingStep(
                actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                models: [.gpt4o, .gpt4_turbo]
            ) { chosenModelType in
                openAIModelMultipleInterpretation = chosenModelType
                multipleResourceInterpreter.changeLLMSchema(
                    openAIModel: chosenModelType,
                    resourceCountLimit: resourceLimit,
                    resourceSummary: resourceSummary,
                    allowedResourcesFunctionCallIdentifiers: Set(allowedResourceIdentifiers)
                )
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
        case .downloadLocalLLM:
            LLMLocalDownloadView(
                model: .custom(id: "mlx-community/OpenHermes-2.5-Mistral-7B-4bit-mlx"),
                downloadDescription: "Download the LLM model to generate summaries of FHIR resources."
            ) {
                path.removeLast()
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    SettingsView()
}
