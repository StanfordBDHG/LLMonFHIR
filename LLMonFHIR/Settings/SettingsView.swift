//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIRLLM
import SpeziLLMOpenAI
import SpeziOnboarding
import SwiftUI


struct SettingsView: View {
    private enum SettingsDestinations {
        case llmSelection
        case resourceSelection
        case promptSummary
        case promptInterpretation
        case promptMultipleResourceInterpretation
    }
    
    
    @State private var path = NavigationPath()
    @State private var llmSelectionComplete = false
    @Environment(\.dismiss) private var dismiss
    @Environment(FHIRResourceSummary.self) var resourceSummary
    @Environment(FHIRResourceInterpreter.self) var resourceInterpreter
    @Environment(FHIRMultipleResourceInterpreter.self) var multipleResourceInterpreter
    
    @AppStorage(StorageKeys.enableTextToSpeech) private var enableTextToSpeech = StorageKeys.Defaults.enableTextToSpeech
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.Defaults.resourceLimit
    @AppStorage(StorageKeys.allowedResourcesFunctionCallIdentifiers) private var allowedResourceIdentifiers = [String]()
    
    @AppStorage(StorageKeys.llmSourceSummarizationInterpretation) private var llmSourceSummarizationInterpretation =
        StorageKeys.Defaults.llmSourceSummarizationInterpretation
    @AppStorage(StorageKeys.llmOpenAiMultipleInterpretation) private var llmOpenAiMultipleInterpretation =
        StorageKeys.Defaults.llmOpenAiMultipleInterpretation
    
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                llmSettings
                speechSettings
                resourcesLimitSettings
                resourcesSettings
                promptsSettings
            }
                .navigationTitle("SETTINGS_TITLE")
                .navigationDestination(for: SettingsDestinations.self) { destination in
                    navigationDestination(for: destination)
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
            } onEditingChanged: { complete in
                if complete {
                    multipleResourceInterpreter.changeLLMSchema(
                        openAIModel: llmOpenAiMultipleInterpretation,
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
    
    private var llmSettings: some View {
        Section("SETTINGS_LLM") {
            NavigationLink(value: SettingsDestinations.llmSelection) {
                Text("SETTINGS_LLM_SELECTION")
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
    
    
    @MainActor
    private func navigationDestination(for destination: SettingsDestinations) -> some View {    // swiftlint:disable:this function_body_length
        Group {     // swiftlint:disable:this closure_body_length
            switch destination {
            case .llmSelection:
                OnboardingStack(onboardingFlowComplete: $llmSelectionComplete) {
                    // Select model for summarization and interpretation
                    LLMSingleResourceSelectionView()
                    // Multiple Resource Chat always uses OpenAI, collect model type and API key
                    LLMMultipleResourceSelectionView(multipleResourceModel: true)
                    LLMOpenAIAPIKeyView()
                }
                    .onChange(of: llmSelectionComplete) { _, newValue in
                        if newValue {
                            path.removeLast()
                        }
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


#Preview {
    SettingsView()
}
