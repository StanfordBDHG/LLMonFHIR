//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct InspecResourceView: View {
    @EnvironmentObject var fhirResourceInterpreter: FHIRResourceInterpreter<FHIR>
    @EnvironmentObject var fhirResourceSummary: FHIRResourceSummary<FHIR>
    
    @State var error: String?
    @State var interpreting = false
    @State var showResourceChat = false
    @State var loadingSummary = false
    
    var resource: FHIRResource
    
    var presentAlert: Binding<Bool> {
        Binding(
            get: {
                error != nil
            },
            set: { newValue in
                if !newValue {
                    error = nil
                }
            }
        )
    }
    
    var body: some View {
        List {
            summarySection
            interpretationSection
            resourceSection
        }
            .navigationTitle(resource.displayName)
            .alert("FHIR_RESOURCES_INTERPRETATION_ERROR", isPresented: presentAlert, presenting: error) { error in
                Text(error)
            }
            .sheet(isPresented: $showResourceChat) {
                InspectResourceChat(
                    chat: fhirResourceInterpreter.chat(forResource: resource),
                    resource: resource
                )
            }
            .task {
                if fhirResourceInterpreter.interpretations[resource.id] == nil {
                    await interpret()
                }
            }
    }
    
    @ViewBuilder
    private var summarySection: some View {
        Section("FHIR_RESOURCES_SUMMARY_SECTION") {
            if loadingSummary {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let summary = fhirResourceSummary.summaries[resource.id] {
                Text(summary.summary)
                    .multilineTextAlignment(.leading)
            } else {
                Button("FHIR_RESOURCES_SUMMARY_BUTTON") {
                    Task {
                        await loadSummary()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var interpretationSection: some View {
        Section("FHIR_RESOURCES_INTERPRETATION_SECTION") {
            if let interpretation = fhirResourceInterpreter.interpretations[resource.id], !interpretation.isEmpty {
                Text(interpretation)
                    .multilineTextAlignment(.leading)
                if !interpreting {
                    Button(
                        action: {
                            showResourceChat.toggle()
                        },
                        label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("FHIR_RESOURCES_INTERPRETATION_LEARN_MORE_BUTTON")
                            }
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    )
                        .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(alignment: .center) {
                    Text("FHIR_RESOURCES_INTERPRETATION_LOADING")
                        .frame(maxWidth: .infinity)
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
    }
    
    @ViewBuilder
    private var resourceSection: some View {
        Section("FHIR_RESOURCES_INTERPRETATION_RESOURCE") {
            LazyText(text: resource.jsonDescription)
                .fontDesign(.monospaced)
                .lineLimit(1)
                .font(.caption2)
        }
    }
    
    private func loadSummary() async {
        loadingSummary = true
        
        do {
            try await fhirResourceSummary.summarize(resource: resource)
        } catch {
            self.error = error.localizedDescription
        }
        
        loadingSummary = false
    }
    
    private func interpret() async {
        interpreting = true
        
        do {
            try await fhirResourceInterpreter.interpret(resource: resource)
        } catch {
            self.error = error.localizedDescription
        }
        
        interpreting = false
    }
}
