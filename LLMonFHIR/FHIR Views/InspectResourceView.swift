//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SpeziFHIR
import SpeziViews
import SwiftUI


struct InspectResourceView: View {
    @Environment(FHIRResourceSummarizer.self) private var summarizer
    @Environment(SingleFHIRResourceInterpreter.self) private var interpreter
    
    private let resource: FHIRResource
    @State private var summary: FHIRResourceSummarizer.Summary?
    @State private var interpretation: String?
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        List {
            summarySection
            interpretationSection
            resourceSection
        }
        .navigationTitle(resource.displayName)
        .viewStateAlert(state: $viewState)
        .task {
            summary = await summarizer.cachedSummary(forResource: resource)
            interpretation = await interpreter.cachedInterpretation(forResource: resource)
        }
        .asyncButtonProcessingStyle(.listRow)
    }
    
    @ViewBuilder private var summarySection: some View {
        Section("FHIR_RESOURCES_SUMMARY_SECTION") {
            if let summary {
                VStack(alignment: .leading) {
                    Text(summary.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .bold()
                    Text(summary.summary)
                        .multilineTextAlignment(.leading)
                }
            }
            AsyncButton(summary == nil ? "Load Resource Summary" : "Reload Resource Summary", state: $viewState) {
                summary = try await summarizer.summarize(
                    resource: SendableFHIRResource(resource: resource),
                    forceReload: summary != nil
                )
            }
        }
    }
    
    @ViewBuilder private var interpretationSection: some View {
        Section("FHIR_RESOURCES_INTERPRETATION_SECTION") {
            if let interpretation, !interpretation.isEmpty {
                Text(interpretation)
                    .multilineTextAlignment(.leading)
            }
            AsyncButton(interpretation == nil ? "Load Resource Interpretation" : "Update Resource Interpretation", state: $viewState) {
                interpretation = try await interpreter.interpret(
                    resource: SendableFHIRResource(resource: resource),
                    forceReload: interpretation != nil
                )
            }
        }
    }
    
    @ViewBuilder private var resourceSection: some View {
        Section("FHIR_RESOURCES_INTERPRETATION_RESOURCE") {
            LazyText(verbatim: resource.jsonDescription)
                .fontDesign(.monospaced)
                .lineLimit(1)
                .font(.caption2)
        }
    }
    
    init(resource: FHIRResource) {
        self.resource = resource
    }
}
