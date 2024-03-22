//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SpeziLLMOpenAI
import SpeziOnboarding
import SwiftUI


/// Displays an multi-step onboarding flow for the Spezi LLMonFHIR.
struct OnboardingFlow: View {
    @Environment(HealthKit.self) private var healthKit: HealthKit?
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    
    private var healthKitAuthorization: Bool {
        // As HealthKit not available in preview simulator
        if ProcessInfo.processInfo.isPreviewSimulator {
            return false
        }
        
        return healthKit?.authorized ?? false
    }
    
    
    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
            Welcome()
            Disclaimer()
            OpenAIAPIKey()
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
