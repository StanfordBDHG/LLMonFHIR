//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ModelsR4
import SpeziFHIR


extension FHIRStore {
    var allResources: [FHIRResource] {
        allergyIntolerances + conditions + diagnostics + encounters + immunizations + medications + observations + otherResources + procedures
    }
    
    var allResourcesFunctionCallIdentifier: [String] {
        var stringResourcesArray = allResources.map { $0.functionCallIdentifier }
        stringResourcesArray.append("N/A")
        return stringResourcesArray
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
