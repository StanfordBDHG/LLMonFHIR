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
    @EnvironmentObject private var onboardingNavigationPath: OnboardingNavigationPath
    
    
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
                onboardingNavigationPath.nextStep()
            }
        )
    }
}


#if DEBUG
struct Disclaimer_Previews: PreviewProvider {
    static var previews: some View {
        Disclaimer()
    }
}
#endif
