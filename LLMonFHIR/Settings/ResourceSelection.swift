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
import SpeziFoundation
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
                            Text("Loading Resources…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        FHIRBundleSelector(bundles: bundles)
                            .pickerStyle(.inline)
                    }
                }
            }
        }
        .navigationTitle("Resource Settings")
        .task {
            showBundleSelection = !standard.useHealthKitResources || !HKHealthStore.isHealthDataAvailable()
            self.bundles = await loadBundles()
        }
        .onDisappear {
            _Concurrency.Task {
                await fhirInterpretationModule.updateSchemas()
            }
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
            store.load(bundle: firstMockPatient)
        }
    }
    
    private func loadBundles() async -> [ModelsR4.Bundle] {
        var bundles: [ModelsR4.Bundle] = await [
            .allen322Ferry570,
            .beatris270Bogan287,
            .edythe31Morar593,
            .gonzalo160Duenas839,
            .jacklyn830Veum823,
            .milton509Ortiz186
        ]
        guard let synthPatientsUrl = Foundation.Bundle.main.url(forResource: "Synthetic Patients", withExtension: nil),
              let bundleGroups = try? FileManager.default.contents(of: synthPatientsUrl) else {
            return bundles
        }
        for url in bundleGroups {
            for url in (try? FileManager.default.contents(of: url)) ?? [] {
                do {
                    let data = try Data(contentsOf: url)
                    bundles.append(try JSONDecoder().decode(ModelsR4.Bundle.self, from: data))
                } catch {
                    print("FAILED TO READ BUNDLE AT \(url.lastPathComponent): \(error)")
                }
            }
        }
        return bundles
    }
}
