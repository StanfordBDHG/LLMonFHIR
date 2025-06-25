//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziFHIRMockPatients
import SwiftUI


struct ResourceView: View {
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRStore.self) private var fhirStore
    @Binding var showMultipleResourcesChat: Bool
    
    
    var body: some View {
        FHIRResourcesView(
            navigationTitle: "Your Health Records",
            contentView: {
                FHIRResourcesInstructionsView()
            }
        ) {
            Button(
                action: {
                    showMultipleResourcesChat.toggle()
                },
                label: {
                    HStack(spacing: 8) {
                        if standard.waitingState.isWaiting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text(standard.waitingState.isWaiting ? "Loading Resources" : "Chat with all Resources")
                    }
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
            )
                .buttonStyle(.borderedProminent)
                .padding(-20)
                .disabled(standard.waitingState.isWaiting)
        }
        .task {
            if FeatureFlags.testMode {
                await fhirStore.loadTestingResources()
            }
        }
    }
}
