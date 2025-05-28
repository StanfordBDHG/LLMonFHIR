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
    static let recordTypes: [SampleType<HKClinicalRecord>] = [
        .allergyRecord, .clinicalNoteRecord, .conditionRecord,
        .coverageRecord, .immunizationRecord, .labResultRecord,
        .medicationRecord, .procedureRecord, .vitalSignRecord
    ]
    
    @Dependency(FHIRStore.self) private var fhirStore
    @Dependency(HealthKit.self) private var healthKit
    @Dependency(FHIRInterpretationModule.self) private var fhirInterpretationModule
    
    @MainActor var useHealthKitResources = true

    @MainActor let waitingState = FHIRResourceWaitingState()

    private var samples: [HKSample] = []
    private var waitTask: Task<Void, Error>?
    
    @MainActor
    func configure() {
        Task {
            await self.initialSetup()
        }
    }
    
    private func initialSetup() async {
        if healthKit.isFullyAuthorized {
            await fetchRecordsFromHealthKit()
        }
    }
    
    @MainActor
    func loadHealthKitRecordsIntoFHIRStore() async {
        await fhirStore.removeAllResources()
        for sample in await samples {
            await fhirStore.add(sample: sample)
        }
        useHealthKitResources = true
        if await fhirStore.allResources.isEmpty {
            waitingState.isWaiting = false
        }
    }
    
    
    @MainActor
    func fetchRecordsFromHealthKit() async {
        let healthKit = await self.healthKit
        let records = await withTaskGroup(of: [HKClinicalRecord].self) { taskGroup in
            for recordType in Self.recordTypes {
                taskGroup.addTask {
                    (try? await healthKit.query(recordType, timeRange: .ever)) ?? []
                }
            }
            return await taskGroup.reduce(into: []) { $0.append(contentsOf: $1) }
        }
        await add(records: records)
    }
    
    
    private func add(records: [HKClinicalRecord]) async {
        self.samples.append(contentsOf: records.lazy.map { $0 as HKSample })
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
            for sample in samples {
                await fhirStore.add(sample: sample, loadHealthKitAttachements: true)
            }
        }
    }
    
    
    // HealthKitConstraint
    
    func handleNewSamples<Sample>(_ addedSamples: some Collection<Sample>, ofType sampleType: SampleType<Sample>) async {
        // unused
    }
    
    func handleDeletedObjects<Sample>(_ deletedObjects: some Collection<HKDeletedObject>, ofType sampleType: SampleType<Sample>) async {
        // unused
    }
}
