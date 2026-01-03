//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Observation
import Spezi


@Observable
@MainActor
final class AppState: Module, EnvironmentAccessible, Sendable {
    /// The currently active study.
    var currentStudy: Study?
}
