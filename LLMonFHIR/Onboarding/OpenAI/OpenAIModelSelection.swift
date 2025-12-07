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
    static let supportedModels: [LLMOpenAIParameters.ModelType] = [
        .gpt5,
        .gpt3_5_turbo,
        .gpt4_turbo,
        .gpt4o,
        .o1,
        .o1_mini,
        .o3_mini,
        .o3_mini_high
    ]
    
    @Environment(ManagedNavigationStack.Path.self) private var path
    @LocalPreference(.openAIModel) private var model
    
    
    var body: some View {
        LLMOpenAIModelOnboardingStep(
            actionText: "OPEN_AI_MODEL_SAVE_ACTION",
            models: Self.supportedModels,
            initial: model
        ) { model in
            self.model = model
            self.path.nextStep()
        }
    }
}
