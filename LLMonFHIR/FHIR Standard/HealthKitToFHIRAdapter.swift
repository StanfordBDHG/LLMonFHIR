//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import HealthKitOnFHIR
import Spezi
import SpeziHealthKit


public actor HealthKitToFHIRAdapter: SingleValueAdapter {
    public typealias InputElement = HKSample
    public typealias InputRemovalContext = HKSampleRemovalContext
    public typealias OutputElement = FHIR.BaseType
    public typealias OutputRemovalContext = FHIR.RemovalContext
    
    
    private let hkHealthStore: HKHealthStore?
    
    
    public init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            hkHealthStore = nil
            return
        }
        
        hkHealthStore = HKHealthStore()
    }
    
    
    public func transform(element: InputElement) async throws -> OutputElement {
        if let electrocardiogram = element as? HKElectrocardiogram, let hkHealthStore {
            async let symptoms = try electrocardiogram.symptoms(from: hkHealthStore)
            async let voltageMeasurements = try electrocardiogram.voltageMeasurements(from: hkHealthStore)
            
            return try await electrocardiogram.observation(
                symptoms: symptoms,
                voltageMeasurements: voltageMeasurements
            )
        } else {
            return try element.resource.get()
        }
    }
    
    public func transform(removalContext: InputRemovalContext) throws -> OutputRemovalContext {
        OutputRemovalContext(
            id: removalContext.id.uuidString.asFHIRStringPrimitive(),
            resourceType: try removalContext.sampleType.resourceTyoe
        )
    }
}
