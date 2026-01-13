//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziHealthKit
import SpeziOnboarding
import SpeziViews
import SwiftUI


struct HealthKitPermissions: View {
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(HealthKit.self) var healthKitDataSource: HealthKit?
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationStackPath
    @State var healthKitProcessing = false
    
    
    var body: some View {
        OnboardingView {
            VStack {
                OnboardingTitleView(
                    title: "HEALTHKIT_PERMISSIONS_TITLE",
                    subtitle: "HEALTHKIT_PERMISSIONS_SUBTITLE"
                )
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .accessibilityHidden(true)
                    .font(.system(size: 150))
                    .foregroundColor(.accentColor)
                Text("HEALTHKIT_PERMISSIONS_DESCRIPTION")
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 16)
                Spacer()
            }
        } footer: {
            OnboardingActionsView("HEALTHKIT_PERMISSIONS_BUTTON") {
                healthKitProcessing = true
                do {
                    // HealthKit is not available in the preview simulator.
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        try await _Concurrency.Task.sleep(for: .seconds(5))
                    } else {
                        try await healthKitDataSource?.askForAuthorization()
                        Task {
                            await standard.fetchRecordsFromHealthKit()
                        }
                    }
                } catch {
                    print("Could not request HealthKit permissions.")
                }
                managedNavigationStackPath.nextStep()
                healthKitProcessing = false
            }
        }
        .navigationBarBackButtonHidden(healthKitProcessing)
    }
}


#Preview {
    HealthKitPermissions()
}
