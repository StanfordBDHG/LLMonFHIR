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


@MainActor
@Observable
class FHIRResourceWaitingState {
    var isWaiting = true
}

actor LLMonFHIRStandard: Standard, HealthKitConstraint, EnvironmentAccessible {
    @Dependency(FHIRStore.self) var fhirStore
    @Dependency(FHIRInterpretationModule.self) var fhirInterpretationModule
    
    @MainActor var useHealthKitResources = true

    @MainActor let waitingState = FHIRResourceWaitingState()

    private var samples: [HKSample] = []
    private var waitTask: Task<Void, Error>?

    func add(sample: HKSample) async {
        samples.append(sample)
        if await useHealthKitResources {
            waitTask?.cancel()
            waitTask = Task {
                await MainActor.run {
                    waitingState.isWaiting = true
                }
                
                try? await Task.sleep(for: .seconds(10))
                
                if !Task.isCancelled {
                    await MainActor.run {
                        waitingState.isWaiting = false
                    }
                    await fhirInterpretationModule.updateSchemas()
                }
            }
            
            await fhirStore.add(sample: sample, loadHealthKitAttachements: true)
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
