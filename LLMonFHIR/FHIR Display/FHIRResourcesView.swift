//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ModelsR4
import OpenAI
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziOnboarding
import SpeziOpenAI
import SpeziViews
import SwiftUI

struct FHIRResourcesView: View {
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRStore.self) private var fhirStore
    
    @State private var showMultipleResourcesChat = false
    @State private var searchText = ""
    
    
    var body: some View {
        List {
            FHIRResourcesInstructionsView()
            if searchText.isEmpty {
                chatAllResourceSection
            }
            if fhirStore.allResources.filterByDisplayName(with: searchText).isEmpty {
                Text("FHIR_RESOURCES_EMPTY_SEARCH_MESSAGE")
            } else {
                resourcesSection
            }
        }
            .searchable(text: $searchText)
            .navigationDestination(for: FHIRResource.self) { resource in
                InspectResourceView(resource: resource)
            }
            .task {
                fhirStore.loadMockResources()
            }
            .sheet(isPresented: $showMultipleResourcesChat) {
                MultipleResourcesChatView()
            }
            .navigationTitle("FHIR_RESOURCES_TITLE")
    }
    
    
    @MainActor @ViewBuilder private var chatAllResourceSection: some View {
        Section {
            Button(
                action: {
                    showMultipleResourcesChat.toggle()
                },
                label: {
                    Text("CHAT_WITH_ALL_RESOURCES")
                        .frame(maxWidth: .infinity, minHeight: 38)
                }
            )
                .buttonStyle(.borderedProminent)
                .padding(-20)
        }
    }
    
    @ViewBuilder private var resourcesSection: some View {
        section(for: \.conditions, sectionName: String(localized: "Conditions"))
        section(for: \.diagnostics, sectionName: String(localized: "Diagnostics"))
        section(for: \.encounters, sectionName: String(localized: "Encounters"))
        section(for: \.immunizations, sectionName: String(localized: "Immunizations"))
        section(for: \.medications, sectionName: String(localized: "Medications"))
        section(for: \.observations, sectionName: String(localized: "Observations"))
        section(for: \.procedures, sectionName: String(localized: "Procedures"))
        section(for: \.otherResources, sectionName: String(localized: "Other Resources"))
    }
    
    
    private func section(for keyPath: KeyPath<FHIRStore, [FHIRResource]>, sectionName: String) -> some View {
        var resources = fhirStore[keyPath: keyPath]
        
        if !searchText.isEmpty {
            resources = resources.filterByDisplayName(with: searchText)
        }
        
        guard !resources.isEmpty else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            Section(sectionName) {
                ForEach(resources) { resource in
                    NavigationLink(value: resource) {
                        FHIRResourceSummaryView(resource: resource)
                    }
                }
            }
        )
    }
}
