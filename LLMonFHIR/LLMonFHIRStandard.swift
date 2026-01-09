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
import SpeziFoundation
import SpeziHealthKit
import SpeziViews
import SwiftUI


actor LLMonFHIRStandard: Standard, HealthKitConstraint, EnvironmentAccessible {
    static let recordTypes: [SampleType<HKClinicalRecord>] = [
        .allergyRecord, .clinicalNoteRecord, .conditionRecord,
        .coverageRecord, .immunizationRecord, .labResultRecord,
        .medicationRecord, .procedureRecord, .vitalSignRecord
    ]
    
    private let logger = Logger(subsystem: "edu.stanford.bdhg.llmonfhir", category: "LLMonFHIRStandard")
    
    @Dependency(FHIRStore.self) private var fhirStore
    @Dependency(HealthKit.self) private var healthKit
    @MainActor @Dependency(FHIRInterpretationModule.self) private var fhirInterpretationModule
    
    @LocalPreference(.resourceLimit) private var resourceLimit
    @MainActor var useHealthKitResources = true
    
    @MainActor @Dependency private var waitingState = FHIRResourceWaitingState()
    
    @MainActor
    func configure() {
        Task {
            await waitingState.run {
                await initialSetup()
            }
        }
    }
    
    private func initialSetup() async {
        await healthKit.waitForConfigurationDone()
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
        await healthKit.triggerDataSourceCollection()
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
    }
    
    @MainActor
    private func updateSchemas() async {
        await fhirInterpretationModule.updateSchemas()
    }
    
    // HealthKitConstraint
    
    func handleNewSamples<Sample>(_ addedSamples: some Collection<Sample>, ofType sampleType: SampleType<Sample>) async {
        for sample in addedSamples {
            guard let sample = sample as? HKClinicalRecord else {
                continue
            }
            try? await fhirStore.add(sample)
        }
    }
    
    func handleDeletedObjects<Sample>(_ deletedObjects: some Collection<HKDeletedObject>, ofType sampleType: SampleType<Sample>) async {
        for object in deletedObjects {
            await fhirStore.remove(object)
        }
    }
}
