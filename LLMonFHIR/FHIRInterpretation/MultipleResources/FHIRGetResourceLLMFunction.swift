//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os
import SpeziFHIR
import SpeziLLMOpenAI


struct FHIRGetResourceLLMFunction: LLMFunction {
    static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")
    
    static let name = "get_resources"
    static let description = String(localized: "FUNCTION_DESCRIPTION")
    
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    
    @Parameter var resources: [String]
    
    
    init(
        fhirStore: FHIRStore,
        resourceSummary: FHIRResourceSummary,
        resourceCountLimit: Int,
        allowedResourcesFunctionCallIdentifiers: Set<String>? = nil // swiftlint:disable:this discouraged_optional_collection
    ) {
        self.fhirStore = fhirStore
        self.resourceSummary = resourceSummary
        
        // Only take newest values of the health records
        var allResourcesFunctionCallIdentifiers = Set(fhirStore.allResourcesFunctionCallIdentifier.suffix(resourceCountLimit))
        
        // If identifiers are restricted, filter for only allowed function call identifiers of health records.
        if let allowedResourcesFunctionCallIdentifiers {
            allResourcesFunctionCallIdentifiers.formIntersection(allowedResourcesFunctionCallIdentifiers)
        }
        
        _resources = Parameter(
            description: String(localized: "PARAMETER_DESCRIPTION"),
            enum: Array(allResourcesFunctionCallIdentifiers)
        )
    }
    
    
    private static func filterFittingResources(_ fittingResources: [FHIRResource]) -> [FHIRResource] {
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
        var functionOutput: [String] = []
        
        try await withThrowingTaskGroup(of: [String].self) { outerGroup in
            // Iterate over all requested resources by the LLM
            for requestedResource in resources {
                outerGroup.addTask { @Sendable [fhirStore, resourceSummary] in
                    // Fetch relevant FHIR resources matching the resources requested by the LLM
                    var fittingResources = fhirStore.llmRelevantResources.filter { $0.functionCallIdentifier.contains(requestedResource) }
                    
                    // Stores output of nested task group summarizing fitting resources
                    var nestedFunctionOutputResults = [String]()
                    
                    guard !fittingResources.isEmpty else {
                        nestedFunctionOutputResults.append(
                            String(
                                localized: "The medical record does not include any FHIR resources for the search term \(requestedResource)."
                            )
                        )
                        return []
                    }
                    
                    // Filter out fitting resources (if greater than 64 entries)
                    fittingResources = Self.filterFittingResources(fittingResources)
                    try await withThrowingTaskGroup(of: String.self) { innerGroup in
                        // Iterate over fitting resources and summarizing them
                        for resource in fittingResources {
                            innerGroup.addTask { @Sendable [resourceSummary] in
                                let summary = try await resourceSummary.summarize(resource: resource)
                                Self.logger.debug("Summary of appended FHIR resource \(requestedResource): \(summary.description)")
                                return String(localized: "This is the summary of the requested \(requestedResource):\n\n\(summary.description)")
                            }
                        }
                        
                        for try await nestedResult in innerGroup {
                            nestedFunctionOutputResults.append(nestedResult)
                        }
                    }
                    
                    return nestedFunctionOutputResults
                }
            }
            
            for try await result in outerGroup {
                functionOutput.append(contentsOf: result)
            }
        }
        
        return functionOutput.joined(separator: "\n\n")
    }
}
