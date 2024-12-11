//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziViews
import SwiftUI


/// Displays a FHIR resource, a summary if loaded, and provides a mechanism to load a summary using a context menu.
public struct FHIRResourceSummaryView: View {
    @Environment(FHIRResourceSummary.self) private var fhirResourceSummary
    
    @State private var viewState: ViewState = .idle
    private let resource: FHIRResource
    
    
    public var body: some View {
        Group {
            if let summary = fhirResourceSummary.cachedSummary(forResource: resource) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(summary.title)
                    if let date = resource.date {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    Text(summary.summary)
                        .font(.caption)
                        .padding(.top, 4)
                }
                    .multilineTextAlignment(.leading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(resource.displayName)
                    if let date = resource.date {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    if viewState == .processing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.vertical, 6)
                            .padding(.top, 4)
                    }
                }
                    .contextMenu {
                        contextMenu
                    }
            }
        }
            .viewStateAlert(state: $viewState)
    }
    
    
    @ViewBuilder private var contextMenu: some View {
        Button(String(localized: "Create Resource Summary")) {
            Task {
                viewState = .processing
                do {
                    try await fhirResourceSummary.summarize(resource: resource)
                    viewState = .idle
                } catch {
                    viewState = .error(
                        AnyLocalizedError(
                            error: error,
                            defaultErrorDescription: String(localized: "Could not create FHIR Summary")
                        )
                    )
                }
            }
        }
    }
    
    
    public init(resource: FHIRResource) {
        self.resource = resource
    }
}
