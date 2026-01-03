//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFoundation
import SpeziLLMFog
import SpeziViews
import SwiftUI


struct FogModelSelectionView: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath
    @LocalPreference(.fogModel) private var fogModel
    
    
    var body: some View {
        LLMFogModelOnboardingStep(
            actionText: "FOG_MODEL_SAVE_ACTION",
            models: [ // explicitly list available models
                .llama3_1_8B,
                .llama3_2,
                .phi4,
                .gemma_7B,
                .deepSeekR1
            ]
        ) { model in
            self.fogModel = model
            self.onboardingNavigationPath.nextStep()
        }
    }
}
