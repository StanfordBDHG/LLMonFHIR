//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziViews
import SwiftUI


struct RootView: View {
    @Environment(CurrentStudyManager.self) private var studyManager
    @LocalPreference(.onboardingFlowComplete) private var didCompleteOnboarding
    
    var body: some View {
        // NOTE: the order here matters, since starting a study (eg from the onboarding or via a launch arg)
        // does not mark the onboarding as complete, but we still want to have the study presented.
        VStack {
            if let study = studyManager.currentSurvey {
                SurveyWelcomeView(survey: study)
            } else if !didCompleteOnboarding {
                EmptyView()
            } else {
                HomeView()
            }
        }
        .sheet(isPresented: .constant(!didCompleteOnboarding && studyManager.currentSurvey == nil)) {
            OnboardingFlow()
        }
    }
}
