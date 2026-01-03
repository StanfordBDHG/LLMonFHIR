//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import SwiftUI


struct RootView: View {
    @LocalPreference(.onboardingFlowComplete) private var didCompleteOnboarding
    
    var body: some View {
        VStack {
            if !didCompleteOnboarding {
                EmptyView()
            } else {
                switch LLMonFHIR.mode {
                case .standalone, .test:
                    HomeView()
                case .study(let studyId):
                    if let studyId, let study = AppConfigFile.current().studies.first(where: { $0.id == studyId }) {
                        StudyHomeView(study: study)
                    } else {
                        StudyHomeView(study: nil)
                    }
                }
            }
        }
        .sheet(isPresented: .constant(!didCompleteOnboarding)) {
            OnboardingFlow()
        }
    }
}
