//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SwiftUI


/// Displays a `Form` of all available FHIR resources.
///
/// The ``FHIRResourcesView`` displays a SwiftUI `List` of all available resources in the `SpeziFHIR` [`FHIRStore`](https://swiftpackageindex.com/stanfordspezi/spezifhir/documentation/spezifhir/fhirstore).
/// The FHIR resources are displayed in sections, for example conditions, medications etc.
/// In order to simply locating a concrete FHIR resource, the ``FHIRResourcesView`` provides a search bar on top of the `List`.
///
/// The ``FHIRResourcesView`` contains an optional content as well as action `View` that are located on top of the resource `List` and can be configured via ``FHIRResourcesView/init(navigationTitle:contentView:actionView:)``.
/// The content and action `View`s are placed within the Swift `List` as a `Section`, enabling proper visual integration with the remainder of the `List`.
///
/// - Warning: Ensure that the `SpeziFHIR` [`FHIRStore`](https://swiftpackageindex.com/stanfordspezi/spezifhir/documentation/spezifhir/fhirstore) is properly set up and accessible within the SwiftUI `Environment`.
struct FHIRResourcesView<Content: View, Action: View>: View {
    @Environment(FHIRStore.self) private var fhirStore
    @State private var searchText = ""
    @State private var expandedSections = Set<KeyPath<FHIRStore, [FHIRResource]>>()
    
    private let title: LocalizedStringResource
    private let contentView: Content
    private let actionView: Action
    
    var body: some View {
        Form {
            contentView
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
        }
        .navigationTitle(title)
        .searchable(text: $searchText)
        .navigationDestination(for: FHIRResource.self) { resource in
            InspectResourceView(resource: resource)
        }
    }
    
    @ViewBuilder private var resourcesSection: some View {
        sections(for: [
            .init("Allergies", keyPath: \.allergyIntolerances),
            .init("Conditions", keyPath: \.conditions),
            .init("Diagnostics", keyPath: \.diagnostics),
            .init("Documents", keyPath: \.documents),
            .init("Encounters", keyPath: \.encounters),
            .init("Immunizations", keyPath: \.immunizations),
            .init("Medications", keyPath: \.medications),
            .init("Observations", keyPath: \.observations),
            .init("Procedures", keyPath: \.procedures),
            .init("Other Resources", keyPath: \.otherResources)
        ])
    }
    
    
    /// Creates a ``FHIRResourcesView`` displaying a `List` of all available FHIR resources.
    ///
    /// - Parameters:
    ///    - navigationTitle: The localized title displayed for purposes of navigation.
    ///    - contentView: A custom content `View` that is displayed as the first `Section` of the `List`.
    ///    - actionView: A custom action `View` that is displayed as the second `Section` of the `List`. Only shown if no search `String` is present.
    init(
        _ title: LocalizedStringResource,
        @ViewBuilder content: () -> Content = { EmptyView() },
        @ViewBuilder action: () -> Action = { EmptyView() }
    ) {
        self.title = title
        self.contentView = content()
        self.actionView = action()
    }
}


extension FHIRResourcesView {
    private struct ResourcesSectionDefinition: Equatable {
        let title: String
        let keyPath: KeyPath<FHIRStore, [FHIRResource]>
        
        init(_ title: LocalizedStringResource, keyPath: KeyPath<FHIRStore, [FHIRResource]>) {
            self.title = String(localized: title)
            self.keyPath = keyPath
        }
    }
    
    
    @ViewBuilder
    private func sections(for defs: [ResourcesSectionDefinition]) -> some View {
        let defsWithContent = defs.compactMap { def in
            let resources = filteredResources(for: def.keyPath)
            return !resources.isEmpty ? (def, resources) : nil
        }
        if defsWithContent.isEmpty {
            Text("No Resources Found")
        } else {
            ForEach(defsWithContent, id: \.0.keyPath) { (def: ResourcesSectionDefinition, resources: [FHIRResource]) in
                let showAll = Binding<Bool> {
                    expandedSections.contains(def.keyPath)
                } set: { isExpanded in
                    if isExpanded {
                        expandedSections.insert(def.keyPath)
                    } else {
                        expandedSections.remove(def.keyPath)
                    }
                }
                Section {
                    resourcesList(resources: resources, showAll: showAll)
                } header: {
                    sectionHeaderButton(sectionTitle: def.title, resources: resources, showAll: showAll)
                        .textCase(nil)
                } footer: {
                    let isLast = def == defsWithContent.last?.0
                    if isLast {
                        Text("Total number of resources across all types: \(fhirStore.allResources.count)")
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
    }
    

    private func filteredResources(for keyPath: KeyPath<FHIRStore, [FHIRResource]>) -> [FHIRResource] {
        var resources = fhirStore[keyPath: keyPath]
        if !searchText.isEmpty {
            resources = resources.filterByDisplayName(with: searchText)
        }
        return resources
    }
    
    
    private func sectionHeaderButton(sectionTitle: String, resources: [FHIRResource], showAll: Binding<Bool>) -> some View {
        Button {
            withAnimation {
                showAll.wrappedValue.toggle()
            }
        } label: {
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(resources.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                Spacer()

                if resources.count > 3 {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .rotationEffect(.degrees(showAll.wrappedValue ? 90 : 0))
                        .offset(y: 1)
                        .accessibilityHidden(true)
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
    
    
    @ViewBuilder
    private func resourcesList(resources: [FHIRResource], showAll: Binding<Bool>) -> some View {
        let sortedResources = resources.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        let visibleResources = showAll.wrappedValue ? sortedResources : Array(sortedResources.prefix(3))
        ForEach(visibleResources) { resource in
            NavigationLink(value: resource) {
                FHIRResourceSummaryView(resource: resource)
            }
        }
    }
}
