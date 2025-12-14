//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMFog
import SpeziLLMOpenAI
import SpeziViews


extension LocalPreferenceKeys {
    // MARK: - Onboarding
    /// A `Bool` flag indicating of the onboarding was completed.
    static let onboardingFlowComplete = LocalPreferenceKey<Bool>("onboardingFlow.complete", default: false)
    /// An `LLMSource` flag indicating the source of the model (local vs. fog vs. OpenAI)
    static let llmSource = LocalPreferenceKey<LLMSource>("onboardingFlow.llmsource", default: .openai)
    
    
    // MARK: - Home
    /// Show the onboarding instructions
    static let onboardingInstructions = LocalPreferenceKey<Bool>("resources.onboardingInstructions", default: true)
    
    
    // MARK: - Settings
    /// Indicates if the messages should be spoken
    static let enableTextToSpeech = LocalPreferenceKey<Bool>("settings.enableTextToSpeech", default: false)
    
    /// Indicates the limit of resources that should be included in the all resources query
    static let resourceLimit = LocalPreferenceKey<Int>("settings.resourceLimit", default: 250)
    
    /// Indicates the chosen OpenAI GPT model for multiple resource interpretation
    static let openAIModel = LocalPreferenceKey<LLMOpenAIParameters.ModelType>("settings.openAIModel.multipleResourceInterpretation", default: .gpt4o)
    
    /// Model temperature
    static let openAIModelTemperature = LocalPreferenceKey<Double>("settings.openAIModel.temperature", default: 0)
    
    /// Identifier for selecting a fog model.
    ///
    /// The value should correspond to the registered model name available on the fog node.
    /// LLMonFHIR uses this name to resolve and load the correct model.
    static let fogModel = LocalPreferenceKey<LLMFogParameters.FogModelType>("settings.fogModel", default: .llama3_1_8B)
}
