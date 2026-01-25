//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SpeziFoundation
import SpeziLLMLocalDownload
import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    
    @LocalPreference(.enableTextToSpeech) private var enableTextToSpeech
    @LocalPreference(.resourceLimit) private var resourceLimit
    @LocalPreference(.openAIModel) private var openAIModel
    
    @State private var path = ManagedNavigationStack.Path()
    @State private var didComplete = false
    
    var body: some View {
        ManagedNavigationStack(didComplete: $didComplete, path: path) {
            Form {
                llmSettings
                speechSettings
                resourcesLimitSettings
                resourcesSettings
                promptsSettings
            }
            .navigationTitle("SETTINGS_TITLE")
            .toolbar {
                ToolbarItem {
                    DismissButton()
                }
            }
            .onChange(of: didComplete) { _, newValue in
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
                path.append {
                    ResourceSelection()
                }
            }
        }
    }
    
    private var llmSettings: some View {
        Section("SETTINGS_LLM") {
            // OpenAI settings are always present for the multiple resource chat
            NavigationButton("SETTINGS_OPENAI_KEY") {
                path.append {
                    LLMOpenAIAPITokenOnboardingStep(actionText: "OPEN_AI_KEY_SAVE_ACTION") {
                        await fhirInterpretationModule.updateSchemas()
                        path.removeLast()
                    }
                }
            }
            NavigationButton("SETTINGS_OPENAI_MODEL") {
                path.append {
                    LLMOpenAIModelOnboardingStep(
                        actionText: "OPEN_AI_MODEL_SAVE_ACTION",
                        models: OpenAIModelSelection.supportedModels,
                        initial: openAIModel
                    ) { chosenModelType in
                        openAIModel = chosenModelType
                        Task {
                            await fhirInterpretationModule.updateSchemas()
                            path.removeLast()
                        }
                    }
                }
            }
            NavigationButton("SETTINGS_OPENAI_MODEL_PARAMETERS") {
                path.append {
                    OpenAIModelParametersView()
                }
            }
            // Ability to change models for the single resource summary / interpretation
            NavigationButton("SETTINGS_LLM_SOURCE") {
                path.append {
                    LLMSourceSelection()
                }
            }
        }
    }

    @ViewBuilder private var promptsSettings: some View {
        let buttons = [
            customizePromptButton(for: .summarizeSingleFHIRResourceDefaultPrompt, label: "SETTINGS_PROMPTS_SUMMARY"),
            customizePromptButton(for: .interpretSingleFHIRResource, label: "SETTINGS_PROMPTS_INTERPRETATION"),
            customizePromptButton(for: .interpretMultipleResourcesDefaultPrompt, label: "SETTINGS_PROMPTS_INTERPRETATION_MULTIPLE_RESOURCES")
        ].compactMap(\.self)
        if !buttons.isEmpty {
            Section("SETTINGS_PROMPTS") {
                ForEach(Array(buttons.indices), id: \.self) { idx in
                    buttons[idx]
                }
            }
        }
    }
    
    private func customizePromptButton(for promptDefinition: FHIRPrompt, label: LocalizedStringResource) -> (some View)? {
        if promptDefinition.isCustomizable {
            NavigationButton(label) {
                path.append {
                    FHIRPromptCustomizationView(label, prompt: promptDefinition) {
                        await fhirInterpretationModule.updateSchemas()
                        path.removeLast()
                    }
                }
            }
        } else {
            nil
        }
    }
}


extension SettingsView {
    private struct NavigationButton: View {
        private let title: LocalizedStringResource
        private let action: @MainActor () -> Void
        
        var body: some View {
            Button {
                action()
            } label: {
                HStack {
                    Text(title)
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
        
        init(_ title: LocalizedStringResource, action: @escaping @MainActor () -> Void) {
            self.title = title
            self.action = action
        }
    }
}
