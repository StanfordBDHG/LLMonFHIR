//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziViews
import SwiftUI


@main
struct LLMonFHIR: App {
    @UIApplicationDelegateAdaptor(LLMonFHIRDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .testingSetup()
                .spezi(appDelegate)
        }
    }
}
