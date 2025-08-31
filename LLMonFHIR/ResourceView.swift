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
            chatWithAllResourcesButton
                .padding(-18)
        }
            .task {
                if FeatureFlags.testMode {
                    await fhirStore.loadTestingResources()
                }
            }
    }
    
    private var chatWithAllResourcesButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                _chatWithAllResourcesButton
                #if swift(>=6.2)
                    .buttonStyle(.glassProminent)
                #endif
            } else {
                _chatWithAllResourcesButton
                    .buttonStyle(.borderedProminent)
                    .padding(-8)
            }
        }
    }
    
    private var _chatWithAllResourcesButton: some View {
        Button {
            showMultipleResourcesChat.toggle()
        } label: {
            HStack(spacing: 8) {
                if standard.waitingState.isWaiting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .controlSize(.regular)
                }
                Text(standard.waitingState.isWaiting ? "Loading Resources" : "Chat with all Resources")
            }
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
            .controlSize(.extraLarge)
            .buttonBorderShape(.capsule)
            .disabled(standard.waitingState.isWaiting)
            .animation(.default, value: standard.waitingState.isWaiting)
    }
}
