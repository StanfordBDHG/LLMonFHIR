//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziViews
import SwiftUI

struct InspectResourceView: View {
    @Environment(FHIRResourceInterpreter.self) var fhirResourceInterpreter
    @Environment(FHIRResourceSummary.self) var fhirResourceSummary
    
    @State var interpreting: ViewState = .idle
    @State var loadingSummary: ViewState = .idle
    
    var resource: FHIRResource
    
    
    var body: some View {
        List {
            summarySection
            interpretationSection
            resourceSection
        }
            .navigationTitle(resource.displayName)
            .viewStateAlert(state: $interpreting)
            .viewStateAlert(state: $loadingSummary)
            .task {
                interpret()
            }
    }
    
    @ViewBuilder private var summarySection: some View {
        Section("FHIR_RESOURCES_SUMMARY_SECTION") {
            if loadingSummary == .processing {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let summary = fhirResourceSummary.cachedSummary(forResource: resource) {
                Text(summary)
                    .multilineTextAlignment(.leading)
                    .contextMenu {
                        Button("FHIR_RESOURCES_SUMMARY_BUTTON") {
                            loadSummary(forceReload: true)
                        }
                    }
            } else {
                Button("FHIR_RESOURCES_SUMMARY_BUTTON") {
                    loadSummary()
                }
            }
        }
    }
    
    @ViewBuilder private var interpretationSection: some View {
        Section("FHIR_RESOURCES_INTERPRETATION_SECTION") {
            if let interpretation = fhirResourceInterpreter.cachedInterpretation(forResource: resource), !interpretation.isEmpty {
                Text(interpretation)
                    .multilineTextAlignment(.leading)
                    .contextMenu {
                        Button("FHIR_RESOURCES_INTERPRETATION_BUTTON") {
                            interpret(forceReload: true)
                        }
                    }
            } else if interpreting == .processing {
                VStack(alignment: .center) {
                    Text("FHIR_RESOURCES_INTERPRETATION_LOADING")
                        .frame(maxWidth: .infinity)
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            } else {
                VStack(alignment: .center) {
                    Button("FHIR_RESOURCES_INTERPRETATION_BUTTON") {
                        interpret()
                    }
                }
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
    
    private func loadSummary(forceReload: Bool = false) {
        loadingSummary = .processing
            
        Task {
            do {
                try await fhirResourceSummary.summarize(resource: resource, forceReload: forceReload)
                loadingSummary = .idle
            } catch let error as APIErrorResponse {
                loadingSummary = .error(error)
            } catch {
                loadingSummary = .error("Unknown error")
            }
        }
    }
    
    private func interpret(forceReload: Bool = false) {
        interpreting = .processing
        
        Task {
            do {
                try await fhirResourceInterpreter.interpret(resource: resource, forceReload: forceReload)
                interpreting = .idle
            } catch let error as APIErrorResponse {
                loadingSummary = .error(error)
            } catch {
                loadingSummary = .error("Unknown error")
            }
        }
    }
}
