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
    
    var resource: VersionedResource
    
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
            Section("LLM on FHIR Interpretation") {
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
                                    Text("Learn More ...")
                                }
                                    .frame(maxWidth: .infinity, minHeight: 40)
                            }
                        )
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(alignment: .center) {
                        Text("Loading result ...")
                            .frame(maxWidth: .infinity)
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            Section("FHIR Resource") {
                LazyText(text: resource.jsonDescription)
                    .fontDesign(.monospaced)
                    .lineLimit(1)
                    .font(.caption2)
            }
        }
            .navigationTitle(fhirResourceSummary.summaries[resource.id]?.title ?? resource.compactDescription)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: {
                            Task {
                                await interpret()
                            }
                        },
                        label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    )
                }
            }
            .alert("Error", isPresented: presentAlert, presenting: error) { error in
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
