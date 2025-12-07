//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation


/// A collection of feature flags for the PAWS app.
enum FeatureFlags {
    /// Skips the onboarding flow to enable easier development of features in the application and to allow UI tests to skip the onboarding flow.
    static let skipOnboarding = CommandLine.arguments.contains("--skipOnboarding")
    /// Always show the onboarding when the application is launched. Makes it easy to modify and test the onboarding flow without the need to manually remove the application or reset the simulator.
    static let showOnboarding = CommandLine.arguments.contains("--showOnboarding")
    /// Sets the application in test mode
    static let testMode = CommandLine.arguments.contains("--testMode")
    /// Export the raw JSON for all FHIR resources in the export for the user study
    static let exportRawJSONFHIRResources = CommandLine.arguments.contains("--exportRawJSONFHIRResources")
    
    /// The identifier of a user study the app should be launched into.
    static var enabledUserStudyId: String? {
        CommandLine.arguments.firstIndex(of: "--study").flatMap {
            CommandLine.arguments[safe: $0 + 1]
        }
    }
}
