//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


struct OpenAIAPIKey: View {
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationStackPath
    
    
    var body: some View {
        LLMOpenAIAPITokenOnboardingStep {
            managedNavigationStackPath.nextStep()
        }
    }
}


#Preview {
    OpenAIAPIKey()
}
