//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


struct FogInformationView: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath
    
    
    var body: some View {
        OnboardingView(
            title: "LLM Fog Mode",
            subtitle: "Run LLMs locally. Keep data inside your network.",
            areas: [
                .init(
                    iconSymbol: "network.badge.shield.half.filled",
                    title: "Private by Design",
                    description: "LLM summary and interpretation inference happens directly within your network - nothing is sent to remote servers."
                ),
                .init(
                    iconSymbol: "server.rack",
                    title: "Local Fog Nodes",
                    description: "Computation is performed on so-called fog nodes, running directly inside your own network."
                ),
                .init(
                    iconSymbol: "exclamationmark.circle.fill",
                    title: "Setup Required",
                    description: """
                    A fog node must be configured in your local network. Please consult the LLMonFHIR docs for setup instructions.
                    """
                )
            ],
            actionText: "Start Client Setup",
            action: {
                self.onboardingNavigationPath.append(
                    customView: FogDiscoveryAuthView()
                )
            }
        )
    }
}


#Preview {
    FogInformationView()
}
