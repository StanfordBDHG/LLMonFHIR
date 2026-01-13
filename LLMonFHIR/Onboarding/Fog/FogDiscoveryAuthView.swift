//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMFog
import SpeziViews
import SwiftUI


struct FogDiscoveryAuthView: View {
    @Environment(ManagedNavigationStack.Path.self) private var path
    
    
    var body: some View {
        LLMFogDiscoveryAuthorizationView {
            path.append {
                FogResourceSelectionView()
            }
        }
    }
}
