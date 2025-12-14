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
    static let mode = Mode(argv: CommandLine.arguments)
    
    @UIApplicationDelegateAdaptor(LLMonFHIRDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .testingSetup()
                .spezi(appDelegate)
        }
    }
}


extension LLMonFHIR {
    enum Mode: Equatable {
        /// The app is used by a user who needs to supply their own API key, and then can use the chat.
        case standalone
        case test
        /// The app is used to select and enroll in a study.
        /// - parameter studyId: Optional; the id of the study which the app should automatically start upon launch,
        case study(studyId: String?)
        
        private static var defaultValue: Self {
            AppConfigFile.current().appLaunchMode
        }
        
        init(argv: [String]) {
            guard let idx = argv.firstIndex(of: "--mode") else {
                self = .defaultValue
                return
            }
            switch argv[safe: idx + 1] {
            case "standalone":
                self = .standalone
            case "test":
                self = .test
            case "study":
                if let studyId = argv[safe: idx + 2], !studyId.starts(with: "--") {
                    self = .study(studyId: studyId)
                } else {
                    self = .study(studyId: nil)
                }
            default:
                self = .defaultValue
            }
        }
    }
}
