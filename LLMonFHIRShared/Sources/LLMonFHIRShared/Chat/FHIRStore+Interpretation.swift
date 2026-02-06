//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Foundation
private import ModelsR4
public import SpeziFHIR


extension FHIRStore {
    /// All relevant `FHIRResource`s for the LLM interpretation.
    @MainActor public var llmRelevantResources: Set<FHIRResource> {
        union(
            allergyIntolerances,
            llmConditions,
            diagnostics.uniqueDisplayNames,
            documents,
            encounters.uniqueDisplayNames,
            immunizations,
            llmMedications,
            observations.uniqueDisplayNames,
            procedures.uniqueDisplayNames,
            otherResources.uniqueDisplayNames
        )
    }
    
    /// All `FHIRResource`s.
    @MainActor public var allResources: Set<FHIRResource> {
        union(
            allergyIntolerances,
            conditions,
            diagnostics,
            documents,
            encounters,
            immunizations,
            medications,
            observations,
            procedures,
            otherResources
        )
    }

    @MainActor private var llmConditions: Set<FHIRResource> {
        conditions.filter { resource in
            guard case let .r4(resource) = resource.versionedResource,
                  let condition = resource as? ModelsR4.Condition else {
                return false
            }
            
            return condition.clinicalStatus?.coding?.contains { coding in
                guard coding.system?.value?.url == URL(string: "http://terminology.hl7.org/CodeSystem/condition-clinical"),
                      coding.code?.value?.string == "active" else {
                    return false
                }
                
                return true
            } ?? false
        }
    }
    
    @MainActor private var llmMedications: Set<FHIRResource> {
        func medicationRequest(resource: FHIRResource) -> MedicationRequest? {
            guard case let .r4(resource) = resource.versionedResource,
                  let medicationRequest = resource as? ModelsR4.MedicationRequest else {
                return nil
            }
            return medicationRequest
        }
        
        let outpatientMedications = medications.filter { medication in
            guard let medicationRequest = medicationRequest(resource: medication) else {
                return false
            }
            return medicationRequest.category?.contains { $0.text?.value?.string.lowercased() == "outpatient" } ?? false
        }
        .uniqueDisplayNames
        
        let activeMedications = medications.filter { medication in
            guard let medicationRequest = medicationRequest(resource: medication),
                  medicationRequest.status == .active else {
                return false
            }
            return true
        }
        .uniqueDisplayNames
        
        return union(outpatientMedications, activeMedications)
    }
    
    /// Get the function call identifiers of all available health resources in the `FHIRStore`.
    ///
    /// - Tip: We use an array as the order indicates the sorting, oldest resources come first, newest one last
    @MainActor public var allResourcesFunctionCallIdentifier: [String] {
        let relevantResources: [FHIRResource] = llmRelevantResources
            .lazy
            .filter { $0.date != nil }
            .sorted { $0.date ?? .distantPast < $1.date ?? .distantPast }
        return relevantResources.map { $0.functionCallIdentifier }
    }

    /// Returns a dictionary mapping FHIR resource types to their earliest dates.
    /// These FHIR resources are a limited subset of `llmRelevantResources`, excluding Patient resources, sorted by most recent date, and capped at `limit`.
    @MainActor
    public func earliestDates(limit: Int) -> [String: Date] {
        let recentFHIRResources = llmRelevantResources
            .filter { $0.resourceType != "Patient" && $0.date != nil }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            .prefix(Swift.min(limit, llmRelevantResources.count))

        let resourcesByType = Dictionary(
            grouping: recentFHIRResources,
            by: { $0.resourceType }
        )
        return resourcesByType
            .compactMapValues { resources in
                resources
                    .min(by: { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) })?
                    .date
            }
    }
    
    func llmRelevantResources(filteredBy filter: String) async -> Set<SendableFHIRResource> {
        await MainActor.run {
            llmRelevantResources.reduce(into: []) { result, resource in
                if resource.functionCallIdentifier.contains(filter) {
                    result.insert(SendableFHIRResource(resource: resource))
                }
            }
        }
    }
}


extension Set where Element == FHIRResource {
    fileprivate var uniqueDisplayNames: Self {
        let reducedEncounters = Dictionary(
            map { ($0.displayName, $0) },
            uniquingKeysWith: { first, second in
                if first.date ?? .distantFuture < second.date ?? .distantPast {
                    return second
                } else {
                    return first
                }
            }
        )
        return Self(reducedEncounters.values)
    }
}


private func union<T>(_ sets: Set<T>...) -> Set<T> {
    sets.reduce(into: []) {
        $0.formUnion($1)
    }
}
