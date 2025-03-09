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
                    Text("CHAT_WITH_ALL_RESOURCES")
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
            )
            .buttonStyle(.borderedProminent)
            .padding(-20)
        }
        .task {
            if FeatureFlags.testMode {
                await fhirStore.loadTestingResources()
            }
        }
    }
}
