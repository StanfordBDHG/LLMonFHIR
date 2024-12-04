//
//  LLMSelectionInformationView.swift
//  LLMonFHIR
//
//  Created by Philipp Zagar on 27.11.24.
//

import SwiftUI


struct LLMSelectionInformationView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    
    var body: some View {
        OnboardingView(
            title: "LLM Selection",
            subtitle: "Informations about the LLM selection",
            areas: [
                OnboardingInformationView.Content(
                    icon: {
                        Image(systemName: "shippingbox.fill")
                            .accessibilityHidden(true)
                    },
                    title: "LLM Usage",
                    description: "LLMonFHIR uses Large Languages Models (LLMs) on your health data. In the onboarding process, you are able to select which LLMs types should be used for evaluations of single as well as multiple FHIR resources."
                ),
                OnboardingInformationView.Content(
                    icon: {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .accessibilityHidden(true)
                    },
                    title: "LLM Selection",
                    description: "For the summarization and interpretation of single FHIR resources, LLMonFHIR enables you to pick between local, fog, as well as cloud LLMs. For the multiple FHIR resource evaluation, you are only able to select cloud-based LLMs from OpenAI."
                )
            ],
            actionText: "To LLM Selection",
            action: {
                onboardingNavigationPath.nextStep()
            }
        )
    }
}


#Preview {
    LLMSelectionInformationView()
}
