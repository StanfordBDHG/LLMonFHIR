//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


struct OpenAIModelSelection: View {
    @Environment(ManagedNavigationStack.Path.self) private var onboardingNavigationPath
    @AppStorage(StorageKeys.openAIModel) private var openAIModel = LLMOpenAIParameters.ModelType.gpt5
    
    
    var body: some View {
        LLMOpenAIModelOnboardingStep(
            actionText: "OPEN_AI_MODEL_SAVE_ACTION",
            models: [
                .gpt5,
                .gpt3_5_turbo,
                .gpt4_turbo,
                .gpt4o,
                .o1,
                .o1_mini,
                .o3_mini,
                .o3_mini_high
            ]
        ) { model in
            self.openAIModel = model
            self.onboardingNavigationPath.nextStep()
        }
    }
}
