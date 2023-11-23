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
    @Environment(FHIRMultipleResourceInterpreter.self) private var fhirMultipleResourceInterpreter
    @Environment(FHIRStore.self) private var fhirStore
        
    @State private var showMultipleResourcesChat = false
    @State private var searchText = ""
    @State private var viewState: ViewState = .idle
    
    
    var body: some View {
        NavigationStack {
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
                    OpenAIChatView(
                        chat: fhirMultipleResourceInterpreter.chat(resources: fhirStore.allResources),
                        title: "All FHIR Resources",
                        enableFunctionCalling: true
                    )
                }
                .viewStateAlert(state: $viewState)
                .navigationTitle("FHIR_RESOURCES_TITLE")
        }
    }
    
    
    @ViewBuilder private var chatAllResourceSection: some View {
        Section {
            OnboardingActionsView(
                "CHAT_WITH_ALL_RESOURCES",
                action: {
                    await interpretMultipleResources()
                    showMultipleResourcesChat.toggle()
                }
            )
            .padding(-20)
        }
    }
    
    @ViewBuilder private var resourcesSection: some View {
        section(for: \.conditions)
        section(for: \.diagnostics)
        section(for: \.encounters)
        section(for: \.immunizations)
        section(for: \.medications)
        section(for: \.observations)
        section(for: \.otherResources)
        section(for: \.procedures)
    }
    
    
    private func section(for keyPath: KeyPath<FHIRStore, [FHIRResource]>) -> some View {
        var resources = fhirStore[keyPath: keyPath]
        
        if !searchText.isEmpty {
            resources = resources.filterByDisplayName(with: searchText)
        }
        
        guard !resources.isEmpty else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            ForEach(resources) { resource in
                NavigationLink(value: resource) {
                    FHIRResourceSummaryView(resource: resource)
                }
            }
        )
    }
    
    private func interpretMultipleResources() async {
        do {
            viewState = .processing
            try await fhirMultipleResourceInterpreter.interpretMultipleResources(resources: fhirStore.allResources)
            viewState = .idle
        } catch let error as APIErrorResponse {
            viewState = .error(error)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
}
