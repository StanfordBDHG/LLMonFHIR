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
import SwiftUI


actor LLMonFHIRStandard: Standard, HealthKitConstraint, EnvironmentAccessible {
    @Dependency(FHIRStore.self) var fhirStore
    @Dependency(FHIRInterpretationModule.self) var fhirInterpretationModule
    
    @MainActor var useHealthKitResources = true
    private var samples: [HKSample] = []
    
    
    func add(sample: HKSample) async {
        samples.append(sample)
        if await useHealthKitResources {
            await fhirStore.add(sample: sample, loadHealthKitAttachements: true)
            await fhirInterpretationModule.updateSchemas()
        }
    }
    
    func remove(sample: HKDeletedObject) async {
        samples.removeAll(where: { $0.id == sample.uuid })
        if await useHealthKitResources {
            await fhirStore.remove(sample: sample)
        }
    }
    
    @MainActor
    func loadHealthKitResources() async {
        await fhirStore.removeAllResources()
        
        for sample in await samples {
            await fhirStore.add(sample: sample)
        }
        
        useHealthKitResources = true
    }
}
