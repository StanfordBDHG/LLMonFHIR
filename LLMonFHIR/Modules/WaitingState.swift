//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


@MainActor
@Observable
final class FHIRResourceWaitingState: Module, EnvironmentAccessible, Sendable {
    private var activeTasks = Set<UUID>()
    
    var isWaiting: Bool {
        !activeTasks.isEmpty
    }
    
    nonisolated init() {}
    
    func run<R, E>(_ operation: sending () async throws(E) -> R) async throws(E) -> R {
        let id = UUID()
        activeTasks.insert(id)
        defer {
            activeTasks.remove(id)
        }
        return try await operation()
    }
}


@propertyWrapper
@MainActor
struct WaitingState: DynamicProperty {
    @Environment(FHIRResourceWaitingState.self) private var waitingState
    
    var wrappedValue: Self {
        self
    }
    
    var isWaiting: Bool {
        waitingState.isWaiting
    }
    
    func run<R: Sendable, E>(_ operation: sending () async throws(E) -> R) async throws(E) -> R {
        try await waitingState.run(operation)
    }
}
