//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziAccessGuard
import SwiftUI


@main
struct LLMonFHIR: App {
    @UIApplicationDelegateAdaptor(LLMonFHIRDelegate.self) var appDelegate
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false


    var body: some Scene {
        WindowGroup {
            contentView
                .sheet(isPresented: .constant(!completedOnboardingFlow)) {
                    OnboardingFlow()
                }
                .testingSetup()
                .spezi(appDelegate)
        }
    }

    @ViewBuilder private var contentView: some View {
        if !completedOnboardingFlow {
            EmptyView()
        } else if FeatureFlags.isUserStudyEnabled {
            UserStudyWelcomeView()
        } else {
            HomeView()
        }
    }
}
