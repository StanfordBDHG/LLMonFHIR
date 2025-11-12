//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMLocalDownload
import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


struct SettingsView: View {
    struct NavigationButton: View {
        let titleKey: LocalizedStringKey
        let action: @MainActor () -> Void
        
        var body: some View {
            Button {
                self.action()
            } label: {
                HStack {
                    Text(self.titleKey)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        
        init(_ titleKey: LocalizedStringKey, action: @escaping @MainActor () -> Void) {
            self.titleKey = titleKey
            self.action = action
        }
    }
    
    @State private var path = ManagedNavigationStack.Path()
    @State private var didComplete = false
    @Environment(\.dismiss) private var dismiss
    
    @Environment(FHIRInterpretationModule.self) var fhirInterpretationModule
    
    @AppStorage(StorageKeys.enableTextToSpeech) private var enableTextToSpeech = StorageKeys.currentEnableTextToSpeech
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.currentResourceCountLimit
    @AppStorage(StorageKeys.openAIModel) private var openAIModel = StorageKeys.currentOpenAIModel
    @AppStorage(StorageKeys.isUsabilityStudyEnabled) private var enableUsabilityStudy = CommandLine.arguments.contains("--userStudy")
    
    
    var body: some View {
        ManagedNavigationStack(didComplete: self.$didComplete, path: self.path) {
            List {
                llmSettings
                speechSettings
                resourcesLimitSettings
                resourcesSettings
                promptsSettings
                usabilityStudySettings
            }
                .navigationTitle("SETTINGS_TITLE")
                .toolbar {
                    ToolbarItem {
                        DismissButton()
                    }
                }
                .onChange(of: self.didComplete) { _, newValue in
                    if newValue {
                        Task {
                            await fhirInterpretationModule.updateSchemas()
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
                    Task {
                        await fhirInterpretationModule.updateSchemas()
                    }
                }
            }
        }
    }
    
    private var resourcesSettings: some View {
        Section("Resource Selection") {
            NavigationButton("Resource Selection") {
                self.path.append(
                    customView: ResourceSelection()
                )
            }
        }
    }
    
    private var llmSettings: some View {
        Section("SETTINGS_LLM") {
            // OpenAI settings are always present for the multiple resource chat
            NavigationButton("SETTINGS_OPENAI_KEY") {
                path.append(
                    customView: LLMOpenAIAPITokenOnboardingStep(actionText: "OPEN_AI_KEY_SAVE_ACTION") {
                        await fhirInterpretationModule.updateSchemas()
                        path.removeLast()
                    }
                )
            }
            NavigationButton("SETTINGS_OPENAI_MODEL") {
                path.append(
                    customView: LLMOpenAIModelOnboardingStep(
                        actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                        models: [.gpt5, .gpt4o, .gpt4_turbo, .gpt3_5_turbo]
                    ) { chosenModelType in
                        openAIModel = chosenModelType
                        Task {
                            await fhirInterpretationModule.updateSchemas()
                            path.removeLast()
                        }
                    }
                )
            }
            NavigationButton("SETTINGS_OPENAI_MODEL_PARAMETERS") {
                path.append(
                    customView: OpenAIModelParametersView()
                )
            }
            // Ability to change models for the single resource summary / interpretation
            NavigationButton("SETTINGS_LLM_SOURCE") {
                path.append(
                    customView: LLMSourceSelection()
                )
            }
        }
    }

    private var promptsSettings: some View {
        Section("SETTINGS_PROMPTS") {
            NavigationButton("SETTINGS_PROMPTS_SUMMARY") {
                path.append(
                    customView: FHIRPromptSettingsView(promptType: .summary) {
                        await fhirInterpretationModule.updateSchemas()
                        path.removeLast()
                    }
                )
            }
            NavigationButton("SETTINGS_PROMPTS_INTERPRETATION") {
                path.append(
                    customView: FHIRPromptSettingsView(promptType: .interpretation) {
                        await fhirInterpretationModule.updateSchemas()
                        path.removeLast()
                    }
                )
            }
            NavigationButton("SETTINGS_PROMPTS_INTERPRETATION_MULTIPLE_RESOURCES") {
                path.append(
                    customView: FHIRPromptSettingsView(promptType: .interpretMultipleResources) {
                        await fhirInterpretationModule.updateSchemas()
                        path.removeLast()
                    }
                )
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
}

#Preview {
    SettingsView()
}
