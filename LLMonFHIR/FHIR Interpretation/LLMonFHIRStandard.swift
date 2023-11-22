//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziFHIR
import SpeziFHIRHealthKit
import SpeziHealthKit


actor LLMonFHIRStandard: Standard, HealthKitConstraint {
    @Dependency var fhirStore: FHIRStore
    
    
    func add(sample: HKSample) async {
        await fhirStore.add(sample: sample)
    }
    
    func remove(sample: HKDeletedObject) async {
        await fhirStore.remove(sample: sample)
    }
}
