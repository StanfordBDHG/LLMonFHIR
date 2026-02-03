//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import LLMonFHIRStudyDefinitions
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
                    if let studyId, let study = Study.withId(studyId), let studyConfig = AppConfigFile.current().studyConfigs[studyId] {
                        StudyHomeView(study: study, config: studyConfig, userInfo: [:])
                    } else {
                        StudyHomeView()
                    }
                }
            }
        }
        .sheet(isPresented: .constant(!didCompleteOnboarding)) {
            OnboardingFlow()
        }
    }
}
