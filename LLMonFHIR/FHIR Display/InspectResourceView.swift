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
    @State var error: String?
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
            .navigationTitle(resource.compactDescription)
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
            .task {
                if fhirResourceInterpreter.interpretations[resource.id] == nil {
                    await interpret()
                }
            }
    }
    
    
    private func interpret() async {
        do {
            try await fhirResourceInterpreter.interpret(resource: resource)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
