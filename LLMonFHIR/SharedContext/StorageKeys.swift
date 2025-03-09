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
        static let resourceLimit = 300
        static let openAIModel: LLMOpenAIParameters.ModelType = .gpt4o
        static let openAIModelTemperature = 0.0
    }
    
    
    // MARK: - Onboarding
    /// A `Bool` flag indicating of the onboarding was completed.
    static let onboardingFlowComplete = "onboardingFlow.complete"
    
    
    // MARK: - Home
    /// Show the onboarding instructions
    static let onboardingInstructions = "resources.onboardingInstructions"
    
    // MARK: - Usability Study
    /// Show the onboarding instructions
    static let isUsabilityStudyEnabled = "study.isUsabilityStudyEnabled"
    
    
    // MARK: - Settings
    /// Indicates if the messages should be spoken
    static let enableTextToSpeech = "settings.enableTextToSpeech"
    /// Indicates the limit of resources that should be included in the all resources query
    static let resourceLimit = "settings.resourceLimit"
    /// Indicates allowed resource identifier that can be queried by the LLM via function calling
    static let allowedResourcesFunctionCallIdentifiers = "settings.allowedResourcesFunctionCallIdentifiers"
    /// Indicates the chosen OpenAI GPT model for summarization
    static let openAIModelSummarization = "settings.openAIModel.summarization"
    /// Indicates the chosen OpenAI GPT model for interpretation
    static let openAIModelInterpretation = "settings.openAIModel.interpretation"
    /// Indicates the chosen OpenAI GPT model for multiple resource interpretation
    static let openAIModelMultipleInterpretation = "settings.openAIModel.multipleResourceInterpretation"
    static let openAIModelTemperature = "settings.openAIModel.temperature"
}
