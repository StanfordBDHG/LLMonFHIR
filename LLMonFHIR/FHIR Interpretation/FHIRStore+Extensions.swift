//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

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
}
