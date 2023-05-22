//
//  ResourceSummaryView.swift
//  LLMonFHIR
//
//  Created by Paul Shmiedmayer on 5/22/23.
//

import SwiftUI


struct ResourceSummaryView: View {
    @EnvironmentObject var fhirResourceSummary: FHIRResourceSummary<FHIR>
    
    @State var loading = false
    
    let resource: VersionedResource
    
    
    var body: some View {
        ZStack {
            if let summary = fhirResourceSummary.summaries[resource.id] {
                VStack(alignment: .leading) {
                    Text(summary.title)
                    Text(summary.summary)
                        .font(.caption)
                }
                    .multilineTextAlignment(.leading)
            } else {
                VStack(alignment: .leading) {
                    Text("Resource with ID: \(resource.id ?? "-")")
                    if loading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                    .contextMenu {
                        Button("Load Resource Summary") {
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
