//
// This source file is part of the Stanford HealthGPT project
//
// SPDX-FileCopyrightText: 2024 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct LLMSourceSelectionView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @AppStorage(StorageKeys.llmSourceSummarizationInterpretation) private var llmSource = StorageKeys.Defaults.llmSourceSummarizationInterpretation

    
    var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    OnboardingTitleView(
                        title: "LLM_SOURCE_SELECTION_TITLE",
                        subtitle: "LLM_SOURCE_SELECTION_SUBTITLE"
                    )
                    Spacer()
                    sourceSelector
                    Spacer()
                }
            },
            actionView: {
                OnboardingActionsView(
                    "LLM_SOURCE_SELECTION_BUTTON"
                ) {
                    switch llmSource {
                    case .local: onboardingNavigationPath.append(customView: LLMLocalDownloadView())    // Next step, download model
                    case .fog: onboardingNavigationPath.nextStep()  // Next step, select OpenAI model (resource chat), collect OpenAI Key
                    case .openAi: onboardingNavigationPath.append(
                        // Next step, select OpenAI model (summarization & interpretation)
                        customView: LLMOpenAIModelOnboardingView(multipleResourceModel: false)
                    )
                    }
                }
            }
        )
    }

    private var sourceSelector: some View {
        Picker("LLM_SOURCE_PICKER_LABEL", selection: $llmSource) {
            ForEach(LLMSourceSummarizationInterpretation.allCases) { source in
                Text(source.localizedDescription)
                    .tag(source)
            }
        }
        .pickerStyle(.inline)
        .accessibilityIdentifier("llmSourcePicker")
    }
}

#Preview {
    LLMSourceSelectionView()
}
