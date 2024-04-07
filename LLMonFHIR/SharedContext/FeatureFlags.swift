//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

/// A collection of feature flags for the PAWS app.
enum FeatureFlags {
    /// Skips the onboarding flow to enable easier development of features in the application and to allow UI tests to skip the onboarding flow.
    static let skipOnboarding = CommandLine.arguments.contains("--skipOnboarding")
    /// Always show the onboarding when the application is launched. Makes it easy to modify and test the onboarding flow without the need to manually remove the application or reset the simulator.
    static let showOnboarding = CommandLine.arguments.contains("--showOnboarding")
    /// Sets the application in test mode
    static let testMode = CommandLine.arguments.contains("--testMode")
    /// Use mock patients
    static let mockPatients = CommandLine.arguments.contains("--mockPatients")
}
