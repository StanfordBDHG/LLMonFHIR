//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct ResourceSummaryView: View {
    @EnvironmentObject var fhirResourceSummary: FHIRResourceSummary<FHIR>
    
    @State var loading = false
    
    let resource: FHIRResource
    
    
    var body: some View {
        ZStack {
            if let summary = fhirResourceSummary.summaries[resource.id] {
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.displayName)
                    Text(summary.summary)
                        .font(.caption)
                }
                    .multilineTextAlignment(.leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.displayName)
                    if loading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.vertical, 6)
                    }
                }
                    .contextMenu {
                        Button("FHIR_RESOURCES_SUMMARY_BUTTON") {
                            Task {
                                loading = true
                                try? await fhirResourceSummary.summarize(resource: resource)
                                loading = false
                            }
                        }
                    }
            }
        }
    }
}
