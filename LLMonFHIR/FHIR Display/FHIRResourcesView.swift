//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ModelsR4
import SpeziOpenAI
import SwiftUI


struct FHIRResourcesView: View {
    @EnvironmentObject var fhirStandard: FHIR
    @State var resources: [String: [FHIRResource]] = [:]
    @State var showSettings = false
    @State var searchText = ""
    @AppStorage(StorageKeys.onboardingInstructions) var onboardingInstructions = true
    
    
    var body: some View {
        NavigationStack {
            List {
                instructionsView
                if filteredResourceKeys.isEmpty {
                    Text("FHIR_RESOURCES_EMPTY_SEARCH_MESSAGE")
                } else {
                    ForEach(filteredResourceKeys, id: \.self) { resourceType in
                        Section(resourceType) {
                            resources(for: resourceType)
                        }
                    }
                }
            }
                .searchable(text: $searchText)
                .navigationDestination(for: FHIRResource.self) { resource in
                    InspectResourceView(resource: resource)
                }
                .onReceive(fhirStandard.objectWillChange) {
                    loadFHIRResources()
                }
                .onAppear {
                    if FeatureFlags.testMode {
                        loadMockResources()
                    }
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
                    SettingsView()
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

    private var filteredResourceKeys: [String] {
        resources.keys.sorted().filter { resourceType in
            guard let resourceArray = resources[resourceType] else {
                return false
            }
            return !resourceArray.filterByDisplayName(with: searchText).isEmpty
        }
    }

    private func resources(for resourceType: String) -> some View {
        let filteredResources = (resources[resourceType] ?? []).filterByDisplayName(with: searchText)

        return ForEach(filteredResources) { resource in
            NavigationLink(value: resource) {
                ResourceSummaryView(resource: resource)
            }
        }
    }

    private func loadMockResources() {
        self.resources = [:]

        let mockObservation = Observation(
            code: CodeableConcept(coding: [Coding(code: "1234".asFHIRStringPrimitive())]),
            status: FHIRPrimitive(ObservationStatus.final)
        )

        let mockFHIRResource = FHIRResource(
            versionedResource: .r4(mockObservation),
            displayName: "Mock Resource"
        )

        self.resources = ["Observation": [mockFHIRResource]]
    }
    
    private func loadFHIRResources() {
        _Concurrency.Task { @MainActor in
            let resources = await fhirStandard.resources
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
