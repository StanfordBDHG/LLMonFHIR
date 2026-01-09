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


struct OpenAIAPIKey: View {
    @Environment(ManagedNavigationStack.Path.self) private var path
    
    
    var body: some View {
        LLMOpenAIAPITokenOnboardingStep {
            path.nextStep()
        }
    }
}


#Preview {
    OpenAIAPIKey()
}
