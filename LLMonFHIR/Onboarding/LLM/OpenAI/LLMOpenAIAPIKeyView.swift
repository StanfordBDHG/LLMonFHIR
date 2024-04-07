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


struct LLMOpenAIAPIKeyView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @Environment(FHIRResourceSummary.self) var resourceSummary
    @Environment(FHIRResourceInterpreter.self) var resourceInterpreter
    @Environment(FHIRMultipleResourceInterpreter.self) var multipleResourceInterpreter
    
    @AppStorage(StorageKeys.llmSourceSummarizationInterpretation) private var llmSourceSummarizationInterpretation =
        StorageKeys.Defaults.llmSourceSummarizationInterpretation
    @AppStorage(StorageKeys.llmOpenAiMultipleInterpretation) private var llmOpenAiMultipleInterpretation =
        StorageKeys.Defaults.llmOpenAiMultipleInterpretation
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.Defaults.resourceLimit
    @AppStorage(StorageKeys.allowedResourcesFunctionCallIdentifiers) private var allowedResourceIdentifiers = [String]()
    
    
    var body: some View {
        LLMOpenAIAPITokenOnboardingStep {
            onboardingNavigationPath.nextStep()
        }
            // Trigger change of llm schemas as soon as token onboarding step is shown
            .task {
                resourceSummary.changeLLMSchema(
                    to: llmSourceSummarizationInterpretation.llmSchema
                )
                
                resourceInterpreter.changeLLMSchema(
                    to: llmSourceSummarizationInterpretation.llmSchema
                )
                
                multipleResourceInterpreter.changeLLMSchema(
                    openAIModel: llmOpenAiMultipleInterpretation,
                    resourceCountLimit: resourceLimit,
                    resourceSummary: resourceSummary,
                    allowedResourcesFunctionCallIdentifiers: Set(allowedResourceIdentifiers)
                )
            }
    }
}


#Preview {
    LLMOpenAIAPIKeyView()
}
