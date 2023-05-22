//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct FHIRResourcesView: View {
    @EnvironmentObject var fhirStandard: FHIR
    @State var resources: [String: [VersionedResource]] = [:]
    
    
    var body: some View {
        NavigationStack {
            List {
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
                .navigationTitle("FHIR Resources")
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
