//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// Displays an multi-step onboarding flow for the Spezi LLMonFHIR.
struct OnboardingFlow: View {
    enum Step: String, Codable {
        case interestingModules
        case healthKitPermissions
    }
    
    @SceneStorage(StorageKeys.onboardingFlowStep) private var onboardingSteps: [Step] = []
    @AppStorage(StorageKeys.onboardingFlowComplete) var completedOnboardingFlow = false
    
    
    var body: some View {
        NavigationStack(path: $onboardingSteps) {
            Welcome(onboardingSteps: $onboardingSteps)
                .navigationDestination(for: Step.self) { onboardingStep in
                    switch onboardingStep {
                    case .interestingModules:
                        InterestingModules(onboardingSteps: $onboardingSteps)
                    case .healthKitPermissions:
                        HealthKitPermissions()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#if DEBUG
struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
    }
}
#endif
