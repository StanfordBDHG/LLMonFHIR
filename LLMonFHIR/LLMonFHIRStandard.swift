//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OSLog
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


actor LLMonFHIRStandard: Standard, HealthKitConstraint, EnvironmentAccessible {
    static let recordTypes: [SampleType<HKClinicalRecord>] = [
        .allergyRecord, .clinicalNoteRecord, .conditionRecord,
        .coverageRecord, .immunizationRecord, .labResultRecord,
        .medicationRecord, .procedureRecord, .vitalSignRecord
    ]
    
    @Dependency(FHIRStore.self) private var fhirStore
    @Dependency(HealthKit.self) private var healthKit
    @MainActor @Dependency(FHIRInterpretationModule.self) private var fhirInterpretationModule
    
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.currentResourceCountLimit
    @MainActor var useHealthKitResources = true
    
    @MainActor @Dependency private var waitingState = FHIRResourceWaitingState()
    
    private let logger = Logger(subsystem: "edu.stanford.bdhg.llmonfhir", category: "LLMonFHIRStandard")
    
    @MainActor
    func configure() {
        Task {
            await waitingState.run {
                await initialSetup()
            }
        }
    }
    
    private func initialSetup() async {
        // Waiting until the HealthKit module loads all authorization requirements.
        // Issue tracked in https://github.com/StanfordSpezi/SpeziHealthKit/issues/57
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
    
    
    @MainActor
    func fetchRecordsFromHealthKit() async {
        await waitingState.run {
            await _fetchRecordsFromHealthKit()
        }
    }
    
    @MainActor
    private func _fetchRecordsFromHealthKit() async {
        guard useHealthKitResources else {
            return
        }
        await fhirStore.removeAllResources()
        let healthKit = await healthKit
        await withTaskGroup { taskGroup in
            for recordType in Self.recordTypes {
                taskGroup.addTask { @concurrent [self] in
                    dispatchPrecondition(condition: .notOnQueue(.main))
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
        await updateSchemas()
    }
    
    private func addRecords(_ records: [HKClinicalRecord]) async {
        await withTaskGroup { taskGroup in
            for record in records {
                taskGroup.addTask { [self] in
                    do {
                        try await fhirStore.add(record, loadHealthKitAttachments: true)
                    } catch {
                        logger.error("Could not transform sample \(record.id) to FHIR resource: \(error)")
                    }
                }
            }
        }
        await updateSchemas()
    }
    
    @MainActor
    private func updateSchemas() async {
        await fhirInterpretationModule.updateSchemas()
    }
    
    // HealthKitConstraint
    
    func handleNewSamples<Sample>(_ addedSamples: some Collection<Sample>, ofType sampleType: SampleType<Sample>) async {
        // unused
    }
    
    func handleDeletedObjects<Sample>(_ deletedObjects: some Collection<HKDeletedObject>, ofType sampleType: SampleType<Sample>) async {
        // unused
    }
}
