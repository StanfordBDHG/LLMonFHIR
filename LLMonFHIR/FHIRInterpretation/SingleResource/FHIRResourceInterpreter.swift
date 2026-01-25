//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LLMonFHIRShared
import SpeziFHIR
import SpeziLLM
import SpeziLocalStorage


/// Responsible for interpreting FHIR resources.
@Observable
final class FHIRResourceInterpreter: Sendable {
    private let resourceProcessor: FHIRResourceProcessor<String>
    
    
    /// - Parameters:
    ///   - localStorage: Local storage module that needs to be passed to the ``FHIRResourceInterpreter`` to allow it to cache interpretations.
    ///   - openAIModel: OpenAI module that needs to be passed to the ``FHIRResourceInterpreter`` to allow it to retrieve interpretations.
    init(
        localStorage: LocalStorage,
        llmRunner: LLMRunner,
        llmSchema: any LLMSchema,
        summarizationPrompt: FHIRPrompt = .summarizeSingleFHIRResourceDefaultPrompt
    ) {
        self.resourceProcessor = FHIRResourceProcessor(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: llmSchema,
            storageKey: "FHIRResourceInterpreter.Interpretations",
            summarizationPrompt: summarizationPrompt
        )
    }
    
    
    /// Interprets a given FHIR resource. Returns a human-readable interpretation.
    ///
    /// - Parameters:
    ///   - resource: The `FHIRResource` to be interpreted.
    ///   - forceReload: A boolean value that indicates whether to reload and reprocess the resource.
    /// - Returns: An asynchronous `String` representing the interpretation of the resource.
    @discardableResult
    func interpret(resource: SendableFHIRResource, forceReload: Bool = false) async throws -> String {
        try await resourceProcessor.process(
            resource: resource,
            forceReload: forceReload
        )
    }
    
    /// Retrieve the cached interpretation of a given FHIR resource. Returns a human-readable interpretation or `nil` if it is not present.
    ///
    /// - Parameter resource: The resource where the cached interpretation should be loaded from.
    /// - Returns: The cached interpretation. Returns `nil` if the resource is not present.
    func cachedInterpretation(forResource resource: FHIRResource) async -> String? {
        await resourceProcessor.results[resource.id]
    }
    
    /// Adjust the LLM schema used by the ``FHIRResourceInterpreter``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    func update(llmSchema schema: any LLMSchema, summarizationPrompt: FHIRPrompt) async {
        await resourceProcessor.update(llmSchema: schema, summarizationPrompt: summarizationPrompt)
    }
}
