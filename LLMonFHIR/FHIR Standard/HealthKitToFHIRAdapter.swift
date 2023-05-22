//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
import HealthKitOnFHIR
import ModelsDSTU2
import Spezi
import SpeziHealthKit


actor HealthKitToFHIRAdapter: SingleValueAdapter {
    typealias InputElement = HKSample
    typealias InputRemovalContext = HKSampleRemovalContext
    typealias OutputElement = FHIR.BaseType
    typealias OutputRemovalContext = FHIR.RemovalContext
    
    
    private let hkHealthStore: HKHealthStore?
    
    
    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            hkHealthStore = nil
            return
        }
        
        hkHealthStore = HKHealthStore()
    }
    
    
    func transform(element: InputElement) async throws -> OutputElement {
        switch element {
        case let clinicalResource as HKClinicalRecord where clinicalResource.fhirResource?.fhirVersion == .primaryDSTU2():
            guard let fhirResource = clinicalResource.fhirResource else {
                throw HealthKitOnFHIRError.invalidFHIRResource
            }
            
            let decoder = JSONDecoder()
            let resourceProxy = try decoder.decode(ModelsDSTU2.ResourceProxy.self, from: fhirResource.data)
            return .dstu2(resourceProxy.get())
        case let electrocardiogram as HKElectrocardiogram:
            guard let hkHealthStore else {
                fallthrough
            }
            
            async let symptoms = try electrocardiogram.symptoms(from: hkHealthStore)
            async let voltageMeasurements = try electrocardiogram.voltageMeasurements(from: hkHealthStore)

            let resource = try await electrocardiogram.observation(
                symptoms: symptoms,
                voltageMeasurements: voltageMeasurements
            )
            return .r4(resource)
        default:
            return try .r4(element.resource.get())
        }
    }
    
    func transform(removalContext: InputRemovalContext) throws -> OutputRemovalContext {
        OutputRemovalContext(
            id: removalContext.id.uuidString,
            resourceType: try removalContext.sampleType.resourceTyoe
        )
    }
}
