//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//


extension Sequence {
    /// asynchronous map operation.
    public func mapAsync<Result, E>(
        isolation actor: isolated (any Actor)? = #isolation,
        _ transform: nonisolated(nonsending) (Element) async throws(E) -> Result
    ) async throws(E) -> [Result] {
        var results: [Result] = []
        results.reserveCapacity(underestimatedCount)
        for element in self {
            results.append(try await transform(element))
        }
        return results
    }
}
