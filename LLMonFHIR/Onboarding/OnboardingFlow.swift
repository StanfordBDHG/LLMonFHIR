//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


/// Displays an multi-step onboarding flow for the Spezi LLMonFHIR.
struct OnboardingFlow: View {
    @Environment(HealthKit.self) private var healthKit: HealthKit?
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    
    private var healthKitAuthorization: Bool {
        // As HealthKit not available in preview simulator
        if ProcessInfo.processInfo.isPreviewSimulator {
            false
        } else {
            healthKit?.isFullyAuthorized ?? false
        }
    }
    
    
    var body: some View {
        ManagedNavigationStack(didComplete: $completedOnboardingFlow) {
            Welcome()
            Disclaimer()
            if !FeatureFlags.isUserStudyEnabled {
                // Always show OpenAI model onboarding for chat-based interaction.
                OpenAIAPIKey()
                // Presents the onboarding flow for the respective local, fog, or cloud LLM.
                LLMSourceSelection()
            }
            if HKHealthStore.isHealthDataAvailable() && !healthKitAuthorization {
                HealthKitPermissions()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#Preview {
    OnboardingFlow()
}
