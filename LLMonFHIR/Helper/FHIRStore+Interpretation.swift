//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
@preconcurrency import ModelsR4
import SpeziFHIR


extension FHIRStore {
    /// All relevant `FHIRResource`s for the LLM interpretation.
    @MainActor public var llmRelevantResources: [FHIRResource] {
        allergyIntolerances
            + llmConditions
            + diagnostics.uniqueDisplayNames
            + documents
            + encounters.uniqueDisplayNames
            + immunizations
            + llmMedications
            + observations.uniqueDisplayNames
            + procedures.uniqueDisplayNames
            + otherResources.uniqueDisplayNames
    }
    
    /// All `FHIRResource`s.
    @MainActor public var allResources: [FHIRResource] {
        allergyIntolerances
            + conditions
            + diagnostics
            + documents
            + encounters
            + immunizations
            + medications
            + observations
            + procedures
            + otherResources
    }

    @MainActor private var llmConditions: [FHIRResource] {
        conditions
            .filter { resource in
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
    
    @MainActor private var llmMedications: [FHIRResource] {
        func medicationRequest(resource: FHIRResource) -> MedicationRequest? {
            guard case let .r4(resource) = resource.versionedResource,
                  let medicationRequest = resource as? ModelsR4.MedicationRequest else {
                return nil
            }
            
            return medicationRequest
        }
        
        let outpatientMedications = medications
            .filter { medication in
                guard let medicationRequest = medicationRequest(resource: medication),
                     medicationRequest.category?
                          .contains(where: { codableconcept in
                              codableconcept.text?.value?.string.lowercased() == "outpatient"
                          })
                          ?? false else {
                    return false
                }
                
                return true
            }
            .uniqueDisplayNames
        
        let activeMedications = medications
            .filter { medication in
                guard let medicationRequest = medicationRequest(resource: medication),
                      medicationRequest.status == .active else {
                    return false
                }
                
                return true
            }
            .uniqueDisplayNames
        
        return outpatientMedications + activeMedications
    }
    
    /// Get the function call identifiers of all available health resources in the `FHIRStore`.
    ///
    /// - Tip: We use an array as the order indicates the sorting, oldest resources come first, newest one last
    @MainActor public var allResourcesFunctionCallIdentifier: [String] {
        let relevantResources: [FHIRResource] = llmRelevantResources
            .lazy
            .filter {
                $0.date != nil
            }
            .sorted {
                $0.date ?? .distantPast < $1.date ?? .distantPast
            }
        
        return relevantResources.map { $0.functionCallIdentifier }
    }

    /// Returns a dictionary mapping FHIR resource types to their earliest dates.
    /// These FHIR resources are a limited subset of `llmRelevantResources`, excluding Patient resources, sorted by most recent date, and capped at `limit`.
    @MainActor
    public func earliestDates(limit: Int) -> [String: Date] {
        let recentFHIRResources = llmRelevantResources
            .filter { $0.resourceType != "Patient" && $0.date != nil }
            .sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })
            .prefix(min(limit, llmRelevantResources.count))

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
    
    func llmRelevantResources(filteredBy filter: String) async -> [SendableFHIRResource] {
        await MainActor.run {
            llmRelevantResources
                .filter {
                    $0.functionCallIdentifier.contains(filter)
                }
                .compactMap {
                    SendableFHIRResource(resource: $0)
                }
        }
    }
}


extension Array where Element == FHIRResource {
    fileprivate var uniqueDisplayNames: [FHIRResource] {
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
        
        return Array(reducedEncounters.values)
    }
}
