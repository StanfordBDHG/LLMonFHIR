//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct Disclaimer: View {
    @Binding private var onboardingSteps: [OnboardingFlow.Step]
    
    
    var body: some View {
        SequentialOnboardingView(
            title: "DISCLAIMER_TITLE".moduleLocalized,
            subtitle: "DISCLAIMER_SUBTITLE".moduleLocalized,
            content: [
                .init(
                    title: "DISCLAIMER_AREA1_TITLE".moduleLocalized,
                    description: "DISCLAIMER_AREA1_DESCRIPTION".moduleLocalized
                ),
                .init(
                    title: "DISCLAIMER_AREA2_TITLE".moduleLocalized,
                    description: "DISCLAIMER_AREA2_DESCRIPTION".moduleLocalized
                ),
                .init(
                    title: "DISCLAIMER_AREA3_TITLE".moduleLocalized,
                    description: "DISCLAIMER_AREA3_DESCRIPTION".moduleLocalized
                ),
                .init(
                    title: "DISCLAIMER_AREA4_TITLE".moduleLocalized,
                    description: "DISCLAIMER_AREA4_DESCRIPTION".moduleLocalized
                ),
                .init(
                    title: "DISCLAIMER_AREA5_TITLE".moduleLocalized,
                    description: "DISCLAIMER_AREA5_DESCRIPTION".moduleLocalized
                )
            ],
            actionText: "DISCLAIMER_BUTTON".moduleLocalized,
            action: {
                onboardingSteps.append(.openAIAPIKey)
            }
        )
    }
    
    
    init(onboardingSteps: Binding<[OnboardingFlow.Step]>) {
        self._onboardingSteps = onboardingSteps
    }
}


#if DEBUG
struct Disclaimer_Previews: PreviewProvider {
    @State private static var path: [OnboardingFlow.Step] = []
    
    
    static var previews: some View {
        Disclaimer(onboardingSteps: $path)
    }
}
#endif
