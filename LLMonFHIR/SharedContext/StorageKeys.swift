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


extension LocalPreferenceKey {
    // MARK: - Onboarding
    /// A `Bool` flag indicating of the onboarding was completed.
    static var onboardingFlowComplete: LocalPreferenceKey<Bool> {
        .make("onboardingFlow.complete", default: false)
    }
    /// An `LLMSource` flag indicating the source of the model (local vs. fog vs. OpenAI)
    static var llmSource: LocalPreferenceKey<LLMSource> {
        .make("onboardingFlow.llmsource", default: .openai)
    }
    
    
    // MARK: - Home
    /// Show the onboarding instructions
    static var onboardingInstructions: LocalPreferenceKey<Bool> {
        .make("resources.onboardingInstructions", default: true)
    }
    
    
    // MARK: - Settings
    /// Indicates if the messages should be spoken
    static var enableTextToSpeech: LocalPreferenceKey<Bool> {
        .make("settings.enableTextToSpeech", default: false)
    }
    
    /// Indicates the limit of resources that should be included in the all resources query
    static var resourceLimit: LocalPreferenceKey<Int> {
        .make("settings.resourceLimit", default: 250)
    }
    
    /// Indicates the chosen OpenAI GPT model for multiple resource interpretation
    static var openAIModel: LocalPreferenceKey<LLMOpenAIParameters.ModelType> {
        .make("settings.openAIModel.multipleResourceInterpretation", default: .gpt4o)
    }
    
    /// Model temperature
    static var openAIModelTemperature: LocalPreferenceKey<Double> {
        .make("settings.openAIModel.temperature", default: 0)
    }
    
    /// Identifier for selecting a fog model.
    ///
    /// The value should correspond to the registered model name available on the fog node.
    /// LLMonFHIR uses this name to resolve and load the correct model.
    static var fogModel: LocalPreferenceKey<LLMFogParameters.FogModelType> {
        .make("settings.fogModel", default: .llama3_1_8B)
    }
}
