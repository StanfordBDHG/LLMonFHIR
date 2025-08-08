//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@preconcurrency import ModelsR4
import os
import SpeziFHIR
import SpeziLLMOpenAI


// @unchecked Sendable can be removed once https://github.com/StanfordSpezi/SpeziLLM/pull/118 is merged.
struct FHIRGetResourceLLMFunction: LLMFunction, @unchecked Sendable {
    static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")
    
    static let name = "get_resources"
    static let description = String(localized: "FUNCTION_DESCRIPTION \(FHIRResource.functionCallIdentifierDateFormatter.string(from: .now))")
    
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    
    @Parameter var resourceCategories: [String]

    
    @MainActor
    init(
        fhirStore: FHIRStore,
        resourceSummary: FHIRResourceSummary,
        resourceCountLimit: Int
    ) {
        self.fhirStore = fhirStore
        self.resourceSummary = resourceSummary
        
        _resourceCategories = Parameter(
            description: String(localized: "PARAMETER_DESCRIPTION \(FHIRResource.functionCallIdentifierDateFormatter.string(from: .now))"),
            enum: fhirStore.allResourcesFunctionCallIdentifier.suffix(resourceCountLimit)
        )
    }
    
    
    private static func filterFittingResources(_ fittingResources: [SendableFHIRResource]) -> [SendableFHIRResource] {
        Self.logger.debug("Overall fitting Resources: \(fittingResources.count)")
        
        var fittingResources = fittingResources
        
        if fittingResources.count > 64 {
            fittingResources = fittingResources.lazy.sorted(by: { $0.date ?? .distantPast < $1.date ?? .distantPast }).suffix(64)
            Self.logger.debug(
                """
                Reduced to the following 64 resources: \(fittingResources.map { $0.functionCallIdentifier }.joined(separator: ","))
                """
            )
        }
        
        return fittingResources
    }
    
    
    func execute() async throws -> String? {
        let allResourceResults = try await processResourceCategories(resourceCategories)
        return allResourceResults.joined(separator: "\n\n")
    }

    private func processResourceCategories(_ resourceCategories: [String]) async throws -> [String] {
        var functionOutput: [String] = []

        try await withThrowingTaskGroup(of: [String].self) { group in
            for resourceCategory in resourceCategories {
                group.addTask {
                    try await self.processResourceCategory(resourceCategory)
                }
            }

            for try await result in group {
                functionOutput.append(contentsOf: result)
            }
        }

        return functionOutput
    }

    private func processResourceCategory(_ resourceCategory: String) async throws -> [String] {
        var fittingResources = await fhirStore.llmRelevantResources(filteredBy: resourceCategory)

        guard !fittingResources.isEmpty else {
            return [
                String(
                    localized: "The medical record does not include any FHIR resources for the search term \(resourceCategory)."
                )
            ]
        }

        fittingResources = Self.filterFittingResources(fittingResources)

        return try await summarizeFHIRResources(fittingResources, resourceCategory: resourceCategory)
    }

    private func summarizeFHIRResources(_ resources: [SendableFHIRResource], resourceCategory: String) async throws -> [String] {
        var summaries: [String] = []

        try await withThrowingTaskGroup(of: String.self) { group in
            for resource in resources {
                group.addTask {
                    try await self.summarizeFHIRResource(resource, resourceCategory: resourceCategory)
                }
            }

            for try await summary in group {
                summaries.append(summary)
            }
        }

        return summaries
    }

    private func summarizeFHIRResource(_ resource: SendableFHIRResource, resourceCategory: String) async throws -> String {
        let summary = try await resourceSummary.summarize(resource: resource)
        Self.logger.debug("Summary of appended FHIR resource category \(resourceCategory): \(summary.description)")
        return String(localized: "This is the summary of the requested \(resourceCategory):\n\n\(summary.description)")
    }
}
