//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SwiftUI


/// Displays a `List` of all available FHIR resources.
///
/// The ``FHIRResourcesView`` displays a SwiftUI `List` of all available resources in the `SpeziFHIR` [`FHIRStore`](https://swiftpackageindex.com/stanfordspezi/spezifhir/documentation/spezifhir/fhirstore).
/// The FHIR resources are displayed in sections, for example conditions, medications etc.
/// In order to simply locating a concrete FHIR resource, the ``FHIRResourcesView`` provides a search bar on top of the `List`.
///
/// The ``FHIRResourcesView`` contains an optional content as well as action `View` that are located on top of the resource `List` and can be configured via ``FHIRResourcesView/init(navigationTitle:contentView:actionView:)``.
/// The content and action `View`s are placed within the Swift `List` as a `Section`, enabling proper visual integration with the remainder of the `List`.
///
/// - Warning: Ensure that the `SpeziFHIR` [`FHIRStore`](https://swiftpackageindex.com/stanfordspezi/spezifhir/documentation/spezifhir/fhirstore) is properly set up and accessible within the SwiftUI `Environment`.
///
/// ### Usage
///
/// The example below showcases a minimal example of using the ``FHIRResourcesView``.
///
/// ```swift
/// struct ResourcesView: View {
///     var body: some View {
///         FHIRResourcesView(navigationTitle: "...") {
///             Button("Some Action") {
///                 // Action to perform
///                 // ...
///             }
///         }
///     }
/// }
/// ```
struct FHIRResourcesView<ContentView: View, ActionView: View>: View {
    @Environment(FHIRStore.self) private var fhirStore
    @State private var searchText = ""
    
    private let navigationTitle: Text
    private let contentView: ContentView
    private let actionView: ActionView
    
    
    var body: some View {
        List {
            Section {
                contentView
            }
            
            if searchText.isEmpty {
                Section {
                    actionView
                }
            }
            
            if fhirStore.allResources.filterByDisplayName(with: searchText).isEmpty {
                Text("FHIR_RESOURCES_EMPTY_SEARCH_MESSAGE")
            } else {
                resourcesSection
            }
            
            Section { } footer: {
                Text("Total Number of Resources: \(fhirStore.allResources.count)")
            }
        }
            .searchable(text: $searchText)
            .navigationDestination(for: FHIRResource.self) { resource in
                InspectResourceView(resource: resource)
            }
            .navigationTitle(navigationTitle)
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
    
    
    /// Creates a ``FHIRResourcesView`` displaying a `List` of all available FHIR resources.
    ///
    /// - Parameters:
    ///    - navigationTitle: The localized title displayed for purposes of navigation.
    ///    - contentView: A custom content `View` that is displayed as the first `Section` of the `List`.
    ///    - actionView: A custom action `View` that is displayed as the second `Section` of the `List`. Only shown if no search `String` is present.
    init(
        navigationTitle: LocalizedStringResource,
        @ViewBuilder contentView: () -> ContentView = { EmptyView() },
        @ViewBuilder _ actionView: () -> ActionView = { EmptyView() }
    ) {
        self.navigationTitle = Text(navigationTitle)
        self.contentView = contentView()
        self.actionView = actionView()
    }
    
    /// Creates a ``FHIRResourcesView`` displaying a `List` of all available FHIR resources.
    ///
    /// - Parameters:
    ///    - navigationTitle: The title displayed for purposes of navigation.
    ///    - contentView: A custom content `View` that is displayed as the first `Section` of the `List`.
    ///    - actionView: A custom action `View` that is displayed as the second `Section` of the `List`. Only shown if no search `String` is present.
    @_disfavoredOverload
    init<Title: StringProtocol>(
        navigationTitle: Title,
        @ViewBuilder contentView: () -> ContentView = { EmptyView() },
        @ViewBuilder _ actionView: () -> ActionView = { EmptyView() }
    ) {
        self.navigationTitle = Text(verbatim: String(navigationTitle))
        self.contentView = contentView()
        self.actionView = actionView()
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
