//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os
import Spezi
import SpeziFHIR
import SpeziFHIRHealthKit
import SpeziHealthKit
import SwiftUI


@globalActor
private actor FHIRProcessingActor: GlobalActor {
    typealias ActorType = FHIRProcessingActor
    
    static let shared = FHIRProcessingActor()
}

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
    
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.currentResourceCountLimit
    @MainActor var useHealthKitResources = true
    @MainActor private(set) var waitingState = FHIRResourceWaitingState()
    @FHIRProcessingActor private var waitTask: Task<Void, Error>?
    
    
    @MainActor
    func configure() {
        Task {
            await self.initialSetup()
        }
    }
    
    private func initialSetup() async {
        let logger = Logger(subsystem: "edu.stanford.bdhg.llmonfhir", category: "LLMonFHIRStandard")
        
        // Waiting until the HealthKit module loads all authorization requirements.
        // Issue tracked in https://github.com/StanfordSpezi/SpeziHealthKit/issues/57.
        let loadingStartDate = Date.now
        while healthKit.configurationState != .completed && abs(loadingStartDate.distance(to: .now)) < 0.5 {
            logger.debug("Loading HealthKit Module ...")
            try? await Task.sleep(for: .seconds(0.02))
        }
        
        guard healthKit.isFullyAuthorized else {
            logger.error("HealthKit permissions not yet provided.")
            return
        }
        
        await fetchRecordsFromHealthKit()
    }
    
    
    func fetchRecordsFromHealthKit() async {
        guard await useHealthKitResources else {
            await MainActor.run {
                waitingState.isWaiting = false
            }
            return
        }
        
        await fhirStore.removeAllResources()
        
        await MainActor.run {
            waitingState.isWaiting = true
        }
        await triggerWaitingTask()
        
        let healthKit = self.healthKit
        await withTaskGroup { taskGroup in
            for recordType in Self.recordTypes {
                taskGroup.addTask { [self] in
                    let records = try? await healthKit.query(
                        recordType,
                        timeRange: .ever,
                        limit: self.resourceLimit,
                        sortedBy: [SortDescriptor(\.startDate, order: .reverse)]
                    )
                    
                    guard let records else {
                        return
                    }
                    
                    await addRecords(records)
                }
            }
        }
    }
    
    private func addRecords(_ records: [HKClinicalRecord]) async {
        await withTaskGroup { sampleTaskGroup in
            for newHealthKitSample in records {
                sampleTaskGroup.addTask { [self] in
                    await triggerWaitingTask()
                    await fhirStore.add(sample: newHealthKitSample, loadHealthKitAttachements: true)
                }
            }
        }
    }
    
    @FHIRProcessingActor
    private func triggerWaitingTask() async {
        waitTask?.cancel()
        waitTask = Task {
            try? await Task.sleep(for: .seconds(10))
            
            if !Task.isCancelled {
                await MainActor.run {
                    waitingState.isWaiting = false
                }
                await fhirInterpretationModule.updateSchemas()
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
