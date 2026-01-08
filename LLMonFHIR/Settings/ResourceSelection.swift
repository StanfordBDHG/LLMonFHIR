//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import HealthKit
@preconcurrency import ModelsR4
import SpeziFHIR
import SpeziFHIRMockPatients
import SwiftUI


struct ResourceSelection: View {
    private static var cachedNICUTestPatients: [Int: ModelsR4.Bundle] = [:]
    
    
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRInterpretationModule.self) var fhirInterpretationModule
    @Environment(FHIRStore.self) private var store
    
    @State private var bundles: [ModelsR4.Bundle] = []
    @State private var showBundleSelection = false
    
    
    @MainActor private var useHealthKitResources: Binding<Bool> {
        Binding {
            if !HKHealthStore.isHealthDataAvailable() {
                showBundleSelection = true
                return false
            }
            return standard.useHealthKitResources
        } set: { newValue in
            showBundleSelection = !newValue
            standard.useHealthKitResources = newValue
        }
    }
    
    var body: some View {
        Form {
            if HKHealthStore.isHealthDataAvailable() {
                Section {
                    Toggle(isOn: useHealthKitResources) {
                        Text("Use HealthKit Resources")
                    }
                }
                    .onChange(of: useHealthKitResources.wrappedValue, initial: true) {
                        changeHealthKitResourcesSelection()
                    }
            }
            if showBundleSelection {
                Section {
                    if bundles.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        FHIRBundleSelector(bundles: bundles)
                            .pickerStyle(.inline)
                    }
                }
            }
        }
        .task {
            showBundleSelection = !standard.useHealthKitResources || !HKHealthStore.isHealthDataAvailable()
            self.bundles = mockPatients
        }
        .onDisappear {
            _Concurrency.Task {
                await fhirInterpretationModule.updateSchemas()
            }
        }
        .navigationTitle(Text("Resource Settings"))
    }
    
    private var mockPatients: [ModelsR4.Bundle] {
        (1...10).map(loadNICUTestPatient(withid:))
    }
    
    
    private func changeHealthKitResourcesSelection() {
        if useHealthKitResources.wrappedValue {
            _Concurrency.Task {
                await standard.fetchRecordsFromHealthKit()
            }
        } else {
            guard let firstMockPatient = bundles.first else {
                return
            }
            
            store.removeAllResources()
            _Concurrency.Task {
                await store.load(bundle: firstMockPatient)
            }
        }
    }
    
    private func loadNICUTestPatient(withid id: Int) -> ModelsR4.Bundle {
        if let cachedNICUTestPatient = Self.cachedNICUTestPatients[id] {
            return cachedNICUTestPatient
        }
        
        let name = "NICU_Synthetic_Patient_\(id)"
        guard let resourceURL = Foundation.Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Could not find the resource \"\(name)\".json in the SpeziFHIRMockPatients Resources folder.")
        }
        
        do {
            let data = try Data(contentsOf: resourceURL)
            let nicuTestPatient = try JSONDecoder().decode(Bundle.self, from: data)
            Self.cachedNICUTestPatients[id] = nicuTestPatient
            return nicuTestPatient
        } catch {
            fatalError("Could not decode the FHIR bundle named \"\(name).json\": \(error)")
        }
    }
}
