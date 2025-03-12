//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLMOpenAI


/// Constants shared across the Spezi Template Application to access storage information including the `AppStorage` and `SceneStorage`
enum StorageKeys {
    private enum Defaults {
        fileprivate static let enableTextToSpeech = false
        fileprivate static let resourceLimit = 250
        fileprivate static let openAIModel: LLMOpenAIParameters.ModelType = .gpt4o
        fileprivate static let openAIModelTemperature = 0.0
    }
    
    
    static var currentEnableTextToSpeech: Bool {
        guard UserDefaults().object(forKey: StorageKeys.enableTextToSpeech) != nil else {
            return StorageKeys.Defaults.enableTextToSpeech
        }
                                                         
        return UserDefaults().bool(forKey: StorageKeys.enableTextToSpeech)
    }
    
    static var currentResourceCountLimit: Int {
        guard UserDefaults().object(forKey: StorageKeys.resourceLimit) != nil else {
            return StorageKeys.Defaults.resourceLimit
        }
                                                         
        return max(0, UserDefaults().integer(forKey: StorageKeys.resourceLimit))
    }
    
    static var currentOpenAIModel: LLMOpenAIParameters.ModelType {
        guard let openAIModelMultipleInterpretation = UserDefaults().string(forKey: StorageKeys.openAIModel),
              let model = LLMOpenAIParameters.ModelType(rawValue: openAIModelMultipleInterpretation) else {
            return StorageKeys.Defaults.openAIModel
        }
                                                         
        return model
    }
    
    static var currentOpenAIModelTemperature: Double {
        guard UserDefaults().object(forKey: StorageKeys.openAIModelTemperature) != nil else {
            return StorageKeys.Defaults.openAIModelTemperature
        }
        
        return max(0.0, UserDefaults().double(forKey: StorageKeys.openAIModelTemperature))
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
    /// Indicates the chosen OpenAI GPT model for multiple resource interpretation
    static let openAIModel = "settings.openAIModel.multipleResourceInterpretation"
    /// Model temperature
    static let openAIModelTemperature = "settings.openAIModel.temperature"
}
