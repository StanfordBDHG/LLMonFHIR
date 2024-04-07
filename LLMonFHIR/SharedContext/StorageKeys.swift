//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI


/// Constants shared across the Spezi Template Application to access storage information including the `AppStorage` and `SceneStorage`
enum StorageKeys {
    enum Defaults {
        static let enableTextToSpeech = false
        static let resourceLimit = 250
        static let llmSourceSummarizationInterpretation: LLMSourceSummarizationInterpretation = .openAi(.gpt4_turbo_preview)
        static let llmOpenAiMultipleInterpretation: LLMOpenAIModelType = .gpt4_turbo_preview
    }
    
    
    // MARK: - Onboarding
    /// A `Bool` flag indicating of the onboarding was completed.
    static let onboardingFlowComplete = "onboardingFlow.complete"
    
    
    // MARK: - Home
    /// Show the onboarding instructions
    static let onboardingInstructions = "resources.onboardingInstructions"
    
    
    // MARK: - Settings
    /// Indicates if the messages should be spoken
    static let enableTextToSpeech = "settings.enableTextToSpeech"
    /// Indicates the limit of resources that should be included in the all resources query
    static let resourceLimit = "settings.resourceLimit"
    /// Indicates allowed resource identifier that can be queried by the LLM via function calling
    static let allowedResourcesFunctionCallIdentifiers = "settings.allowedResourcesFunctionCallIdentifiers"
    /// Indicates the chosen LLM model for summarization / interpretation
    static let llmSourceSummarizationInterpretation = "settings.llmModel.summarizationInterpretation"
    /// Indicates the chosen OpenAI GPT model for multiple resource interpretation
    static let llmOpenAiMultipleInterpretation = "settings.openAIModel.multipleResourceInterpretation"
}
