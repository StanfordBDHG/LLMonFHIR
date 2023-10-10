//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

/// Constants shared across the Spezi Teamplate Application to access storage information including the `AppStorage` and `SceneStorage`
enum StorageKeys {
    enum Defaults {
        static let enableTextToSpeech = false
        static let resourceLimit = 50
    }
    
    
    // MARK: - Onboarding
    /// A `Bool` flag indicating of the onboarding was completed.
    static let onboardingFlowComplete = "onboardingFlow.complete"
    /// A `Step` flag indicating the current step in the onboarding process.
    static let onboardingFlowStep = "onboardingFlow.step"
    
    
    // MARK: - Home
    /// Show the onboarding instructions
    static let onboardingInstructions = "resources.onboardingInstructions"
    
    
    // MARK: - Settings
    /// Indicates if the messages should be spoken
    static let enableTextToSpeech = "settings.enableTextToSpeech"
    /// Indicates the limit of resources that should be included in the all resources query
    static let resourceLimit = "settings.resourceLimit"
}
