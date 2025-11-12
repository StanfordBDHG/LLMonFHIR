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
            self.bundles = await mockPatients
        }
        .onDisappear {
            _Concurrency.Task {
                await fhirInterpretationModule.updateSchemas()
            }
        }
        .navigationTitle(Text("Resource Settings"))
    }
    
    private var mockPatients: [ModelsR4.Bundle] {
        get async {
            await [
                .allen322Ferry570,
                .beatris270Bogan287,
                .edythe31Morar593,
                .gonzalo160Duenas839,
                .jacklyn830Veum823,
                .milton509Ortiz186
            ]
        }
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
}
