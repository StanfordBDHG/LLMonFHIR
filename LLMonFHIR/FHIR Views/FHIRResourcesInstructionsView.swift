//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziViews
import SwiftUI


struct FHIRResourcesInstructionsView: View {
    @Environment(FHIRStore.self) private var fhirStore
    @LocalPreference(.onboardingInstructions) private var onboardingInstructions
    
    
    var body: some View {
        if fhirStore.allResources.isEmpty {
            VStack(alignment: .center) {
                Image(systemName: "doc.text.magnifyingglass")
                    .accessibilityHidden(true)
                    .font(.system(size: 90))
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 8)
                Text("FHIR_RESOURCES_VIEW_NO_RESOURCES")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
            }
        } else if onboardingInstructions {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    if #available(iOS 26.0, *) {
                        dismissButton
                            .buttonStyle(.glass)
                    } else {
                        dismissButton
                    }
                }
                    .padding(.horizontal, -8)
                    .padding(.bottom, -32)
                Image(systemName: "hand.wave.fill")
                    .accessibilityHidden(true)
                    .font(.system(size: 75))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 8)
                Text("FHIR_RESOURCES_VIEW_INSTRUCTION")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
            }
        } else {
            EmptyView()
        }
    }
    
    private var dismissButton: some View {
        Button {
            withAnimation {
                onboardingInstructions = false
            }
        } label: {
            Image(systemName: "xmark")
                .accessibilityLabel("Dismiss onboarding hint")
        }
            .buttonBorderShape(.circle)
            .foregroundColor(.secondary)
    }
}
