//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2024 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


struct LLMSourceSelection: View {
    @Environment(ManagedNavigationStack.Path.self) private var path
    @LocalPreference(.llmSource) private var llmSource

    
    var body: some View {
        OnboardingView(
            content: {
                VStack {
                    OnboardingTitleView(
                        title: "LLM_SOURCE_SELECTION_TITLE",
                        subtitle: "LLM_SOURCE_SELECTION_SUBTITLE"
                    )
                    Spacer()
                    self.sourceSelector
                    Spacer()
                }
            },
            footer: {
                OnboardingActionsView(
                    "LLM_SOURCE_SELECTION_BUTTON"
                ) {
                    switch self.llmSource {
                    case .openai:
                        // OpenAI model info was already collected by previous step, skip the OpenAI key and model selection
                        path.nextStep()
                    case .fog:
                        path.append(customView: FogInformationView())
                    case .local:
                        path.append(customView: LLMLocalDownload())
                    }
                }
            }
        )
    }
    
    private var sourceSelector: some View {
        Picker("LLM_SOURCE_PICKER_LABEL", selection: $llmSource) {
            ForEach(LLMSource.allCases) { source in
                Text(source.localizedDescription)
                    .tag(source)
            }
        }
        .pickerStyle(.inline)
        .accessibilityIdentifier("llmSourcePicker")
    }
}


#Preview {
    LLMSourceSelection()
}
