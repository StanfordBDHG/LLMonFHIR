//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SpeziViews
import SwiftUI

struct InspectResourceView: View {
    @EnvironmentObject var fhirResourceInterpreter: FHIRResourceInterpreter
    @EnvironmentObject var fhirResourceSummary: FHIRResourceSummary
    
    @State var interpreting: ViewState = .idle
    @State var loadingSummary: ViewState = .idle
    @State var showResourceChat = false
    
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
            .sheet(isPresented: $showResourceChat) {
                OpenAIChatView(
                    chat: fhirResourceInterpreter.chat(forResource: resource),
                    title: resource.displayName,
                    enableFunctionCalling: false
                )
            }
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
            } else if let summary = fhirResourceSummary.summaries[resource.id] {
                Text(summary.summary)
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
        Section("FHIR_RESOURCES_INTERPRETATION_SECTION") { // swiftlint:disable:this closure_body_length
            if let interpretation = fhirResourceInterpreter.interpretations[resource.id], !interpretation.isEmpty {
                Text(interpretation)
                    .multilineTextAlignment(.leading)
                    .contextMenu {
                        Button("FHIR_RESOURCES_INTERPRETATION_BUTTON") {
                            interpret(forceReload: true)
                        }
                    }
                if interpreting != .processing {
                    Button(
                        action: {
                            showResourceChat.toggle()
                        },
                        label: {
                            HStack {
                                Image(systemName: "message.fill")
                                    .accessibilityHidden(true)
                                Text("FHIR_RESOURCES_INTERPRETATION_LEARN_MORE_BUTTON")
                            }
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    )
                        .buttonStyle(.borderedProminent)
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
            LazyText(text: resource.jsonDescription)
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
