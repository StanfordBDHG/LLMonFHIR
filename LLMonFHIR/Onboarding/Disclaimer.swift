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
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    
    var body: some View {
        SequentialOnboardingView(
            title: "DISCLAIMER_TITLE",
            subtitle: "DISCLAIMER_SUBTITLE",
            content: [
                .init(
                    title: "DISCLAIMER_AREA1_TITLE",
                    description: "DISCLAIMER_AREA1_DESCRIPTION"
                ),
                .init(
                    title: "DISCLAIMER_AREA2_TITLE",
                    description: "DISCLAIMER_AREA2_DESCRIPTION"
                ),
                .init(
                    title: "DISCLAIMER_AREA3_TITLE",
                    description: "DISCLAIMER_AREA3_DESCRIPTION"
                ),
                .init(
                    title: "DISCLAIMER_AREA4_TITLE",
                    description: "DISCLAIMER_AREA4_DESCRIPTION"
                ),
                .init(
                    title: "DISCLAIMER_AREA5_TITLE",
                    description: "DISCLAIMER_AREA5_DESCRIPTION"
                )
            ],
            actionText: "DISCLAIMER_BUTTON",
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
