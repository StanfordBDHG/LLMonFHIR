//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziViews
import SwiftUI


struct ResourceSummaryView: View {
    @Environment(FHIRResourceSummary.self) var fhirResourceSummary
    
    @State var viewState: ViewState = .idle
    @State var summary: String = ""
    
    let resource: FHIRResource
    
    
    var body: some View {
        ZStack {
            if let summary = fhirResourceSummary.cachedSummary(forResource: resource) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.displayName)
                    Text(summary)
                        .font(.caption)
                }
                    .multilineTextAlignment(.leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.displayName)
                    if viewState == .processing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.vertical, 6)
                    }
                }
                    .contextMenu {
                        Button("FHIR_RESOURCES_SUMMARY_BUTTON") {
                            Task {
                                viewState = .processing
                                do {
                                    try await fhirResourceSummary.summarize(resource: resource)
                                    viewState = .idle
                                } catch {
                                    viewState = .error("Failed to summarize the resource: \(resource)")
                                }
                            }
                        }
                    }
            }
        }
            .viewStateAlert(state: $viewState)
    }
}
