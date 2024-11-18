//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziLLM
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
                #if !TEST
                interpret()
                #endif
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
                VStack {
                    HStack(spacing: 0) {
                        Text(summary.title)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .bold()
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Text(summary.summary)
                            .multilineTextAlignment(.leading)
                            .contextMenu {
                                Button("FHIR_RESOURCES_SUMMARY_BUTTON") {
                                    loadSummary(forceReload: true)
                                }
                            }
                        Spacer()
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
            } catch let error as LLMError {
                loadingSummary = .error(error)
            } catch {
                loadingSummary = .error(LLMDefaultError.unknown(error))
            }
        }
    }
    
    private func interpret(forceReload: Bool = false) {
        interpreting = .processing
        
        Task {
            do {
                try await fhirResourceInterpreter.interpret(resource: resource, forceReload: forceReload)
                interpreting = .idle
            } catch let error as LLMError {
                interpreting = .error(error)
            } catch {
                interpreting = .error(LLMDefaultError.unknown(error))
            }
        }
    }
}
