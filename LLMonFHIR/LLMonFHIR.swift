//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import Spezi
import SwiftUI


@main
struct LLMonFHIR: App {
    static let mode: AppLaunchMode = {
        let argv = CommandLine.arguments
        return argv.firstIndex(of: "--mode")
            .flatMap { argv[safe: $0 + 1] }
            .flatMap { AppLaunchMode(rawValue: $0) }
        ?? AppConfigFile.current().appLaunchMode
    }()
    
    @UIApplicationDelegateAdaptor(LLMonFHIRDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                CreateEnrollmentQRCodeSheet()
            } else {
                RootView()
                    .testingSetup()
                    .spezi(appDelegate)
            }
        }
    }
}
