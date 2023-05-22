//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SpeziOpenAI
import SwiftUI


struct FHIRResourcesView: View {
    @EnvironmentObject var healthKitModule: HealthKit<FHIR>
    @EnvironmentObject var fhirStandard: FHIR
    @State var resources: [String: [VersionedResource]] = [:]
    @State var showSettings = false
    @AppStorage(StorageKeys.onboardingInstructions) var onboardingInstructions = true
    
    
    var body: some View {
        NavigationStack {
            List {
                instructionsView
                ForEach(resources.keys.sorted()) { resourceType in
                    Section(resourceType) {
                        resources(for: resourceType)
                    }
                }
            }
                .navigationDestination(for: VersionedResource.self) { resource in
                    InspecResourceView(resource: resource)
                }
                .onReceive(fhirStandard.objectWillChange) {
                    loadFHIRResources()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(
                            action: {
                                showSettings.toggle()
                            },
                            label: {
                                Image(systemName: "gear")
                            }
                        )
                    }
                }
                .sheet(isPresented: $showSettings) {
                    OpenAIAPIKeyOnboardingStep<FHIR> {
                        showSettings.toggle()
                    }
                }
                .refreshable {
                    await healthKitModule.triggerDataSourceCollection()
                }
                .navigationTitle("FHIR_RESOURCES_TITLE")
        }
    }
    
    @ViewBuilder
    private var instructionsView: some View {
        if resources.isEmpty {
            VStack(alignment: .center) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 90))
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 8)
                Text("FHIR_RESOURCES_VIEW_NO_RESOURCES")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
            }
        } else if onboardingInstructions {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Button(
                        action: {
                            withAnimation {
                                onboardingInstructions = false
                            }
                        },
                        label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                        }
                    )
                }
                    .padding(.horizontal, -8)
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 75))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 8)
                Text("FHIR_RESOURCES_VIEW_INSTRUCTION")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
            }
        } else {
            EmptyView()
        }
    }
    
    
    private func resources(for resourceType: String) -> some View {
        ForEach(resources[resourceType] ?? []) { resource in
            NavigationLink(value: resource) {
                ResourceSummaryView(resource: resource)
            }
        }
    }
    
    private func loadFHIRResources() {
        Task {
            let resources = await Array(fhirStandard.resources.values)
            self.resources = [:]
            for resource in resources {
                var currentResources = self.resources[resource.resourceType, default: []]
                currentResources.append(resource)
                self.resources[resource.resourceType] = currentResources
            }
        }
    }
}

struct FHIRDisplay_Previews: PreviewProvider {
    static var previews: some View {
        FHIRResourcesView()
            .environmentObject(FHIR())
    }
}
