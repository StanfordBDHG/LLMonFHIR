//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ModelsR4
import SpeziFHIR
import SwiftUI


extension FHIRStore {
    var allResources: [FHIRResource] {
        allergyIntolerances + conditions + diagnostics + encounters + immunizations + medications + observations + otherResources + procedures
    }
    
    var allResourcesFunctionCallIdentifier: [String] {
        @AppStorage(StorageKeys.resourceLimit) var resourceLimit = StorageKeys.Defaults.resourceLimit
        
        let relevantResources: [FHIRResource]

        var sortedMedications = medications

        for (index, medication) in sortedMedications.enumerated().reversed() {
            let description = medication.jsonDescription
            let name = medication.displayName
            print("Name of medication: "+name)
            if description.contains("inpatient") || name == "MedicationAdministration"  {
                print("Removed '\(name)'")
                sortedMedications.remove(at: index)
            }
        }
        if allResources.count > resourceLimit {
            var limitedResources: [FHIRResource] = []
            limitedResources.append(contentsOf: allergyIntolerances.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: conditions.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: diagnostics.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: encounters.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: immunizations.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: sortedMedications.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: observations.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: otherResources.dateSuffix(maxLength: resourceLimit / 9))
            limitedResources.append(contentsOf: procedures.dateSuffix(maxLength: resourceLimit / 9))
            relevantResources = limitedResources
        } else {
            relevantResources = allResources
        }
        
        return Array(Set(relevantResources.map { $0.functionCallIdentifier }))
    }
    
    
    func loadMockResources() {
        if FeatureFlags.testMode {
            let mockObservation = Observation(
                code: CodeableConcept(coding: [Coding(code: "1234".asFHIRStringPrimitive())]),
                issued: FHIRPrimitive<Instant>(try? Instant(date: .now)),
                status: FHIRPrimitive(ObservationStatus.final)
            )
            
            let mockFHIRResource = FHIRResource(
                versionedResource: .r4(mockObservation),
                displayName: "Mock Resource"
            )
            
            removeAllResources()
            insert(resource: mockFHIRResource)
        }
    }
}


extension Array where Element == FHIRResource {
    fileprivate func dateSuffix(maxLength: Int) -> [FHIRResource] {
        self.lazy.sorted(by: { $0.date ?? .distantPast < $1.date ?? .distantPast }).suffix(maxLength)
    }
}
