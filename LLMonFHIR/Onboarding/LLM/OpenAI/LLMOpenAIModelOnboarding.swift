//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziOnboarding
import SwiftUI


struct LLMOpenAIModelOnboardingView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @AppStorage(StorageKeys.llmSourceSummarizationInterpretation) private var llmSourceSummarizationInterpretation =
        StorageKeys.Defaults.llmSourceSummarizationInterpretation
    @AppStorage(StorageKeys.llmOpenAiMultipleInterpretation) private var llmOpenAiMultipleInterpretation = 
        StorageKeys.Defaults.llmOpenAiMultipleInterpretation
    
    @State private var modelSelection: LLMOpenAIModelType = .gpt4_turbo_preview
    let multipleResourceModel: Bool
    
    
    var body: some View {
        Group {
            if multipleResourceModel {
                LLMOpenAIModelOnboardingStep(
                    title: LocalizedStringResource("LLM for Multiple Resource Chat"),
                    subtitle: LocalizedStringResource("LLM for Multiple Resource Chat"),
                    selectionDescription: LocalizedStringResource("LLM for Multiple Resource Chat"),
                    models: [.gpt4_turbo_preview, .gpt4]
                ) { model in
                        llmOpenAiMultipleInterpretation = model
                        onboardingNavigationPath.nextStep()
                }
            } else {
                LLMOpenAIModelOnboardingStep(
                    title: LocalizedStringResource("LLM for Summarization / Interpretation"),
                    subtitle: LocalizedStringResource("LLM for Summarization / Interpretation"),
                    selectionDescription: LocalizedStringResource("LLM for Summarization / Interpretation"),
                    models: [.gpt4_turbo_preview, .gpt4, .gpt3_5Turbo]
                ) { model in
                        llmSourceSummarizationInterpretation = .openAi(model)
                        onboardingNavigationPath.nextStep()
                }
            }
        }
    }
}
