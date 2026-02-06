//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

private import ModelsR4
private import os
public import SpeziFHIR
public import SpeziLLMOpenAI


public struct FHIRGetResourceLLMFunction: LLMFunction {
    private static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")
    
    public static let name = "get_resources"
    
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    @Parameter var resourceCategories: [String]
    
    @MainActor
    public init(
        fhirStore: FHIRStore,
        resourceSummary: FHIRResourceSummary,
        resourceCountLimit: Int
    ) {
        self.fhirStore = fhirStore
        self.resourceSummary = resourceSummary
        
        _resourceCategories = Parameter(
            description: """
                Pass in one or more identifiers that you want to access.
                It is possible that multiple titles apply to the users's question (e.g for multiple medications).
                You can also request a larger set of FHIR resources by, e.g., just stating the resource type but this might not include all relevant resources to avoid exceeding the token limit.
                Ensure that you request the most recent information to get a good overview of the user's current health status.
                Today’s date is \(FHIRResource.functionCallIdentifierDateFormatter.string(from: .now)).
                """,
            enum: fhirStore.allResourcesFunctionCallIdentifier.suffix(resourceCountLimit)
        )
    }
    
    
    private static func filterFittingResources(_ fittingResources: some Collection<SendableFHIRResource>) -> [SendableFHIRResource] {
        if fittingResources.count > 64 {
            fittingResources.lazy.sorted(by: { $0.date ?? .distantPast < $1.date ?? .distantPast }).suffix(64)
        } else {
            Array(fittingResources)
        }
    }
    
    
    public func execute() async throws -> String? {
        try await processResourceCategories(resourceCategories)
            .joined(separator: "\n\n")
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
        var fittingResources = await Array(fhirStore.llmRelevantResources(filteredBy: resourceCategory))
        guard !fittingResources.isEmpty else {
            return [String(localized: "The medical record does not include any FHIR resources for the search term \(resourceCategory).")]
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
        return String(localized: "This is the summary of the requested \(resourceCategory):\n\n\(summary.description)")
    }
}


extension FHIRGetResourceLLMFunction {
    // swiftlint:disable:next missing_docs
    public static let description = """
        Call this function to request the relevant FHIR health records based on the user's question and conversation context using their FHIR resource identifiers.

        The FHIR resource identifiers are composed of three elements:
        1. The FHIR resource type, e.g., DocumentReference, DiagnosticReport, MedicationRequest, Encounter, Observation, Procedure, Condition, ...
        2. The descriptive title of the FHIR resource.
        3. The date associated with the FHIR resource.

        Use this information to request the most relevant FHIR resources.
        Pass in one or more resource identifiers that you need access to the `resourceCategories` argument.
        You can also request a more extensive set of FHIR resources by only stating the resource type.

        Use the date in the parameter enum cases to identify relevant resources within the correct time window. Aim to request recent FHIR resources.
        Today's date is \(FHIRResource.functionCallIdentifierDateFormatter.string(from: .now)).
        """
}
