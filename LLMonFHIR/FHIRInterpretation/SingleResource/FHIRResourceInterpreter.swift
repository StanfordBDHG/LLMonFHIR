//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFHIR
import SpeziLLM
import SpeziLocalStorage


/// Responsible for interpreting FHIR resources.
@Observable
public final class FHIRResourceInterpreter: Sendable {
    private let resourceProcessor: FHIRResourceProcessor<String>
    
    
    /// - Parameters:
    ///   - localStorage: Local storage module that needs to be passed to the ``FHIRResourceInterpreter`` to allow it to cache interpretations.
    ///   - openAIModel: OpenAI module that needs to be passed to the ``FHIRResourceInterpreter`` to allow it to retrieve interpretations.
    public init(localStorage: LocalStorage, llmRunner: LLMRunner, llmSchema: any LLMSchema) {
        self.resourceProcessor = FHIRResourceProcessor(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: llmSchema,
            storageKey: "FHIRResourceInterpreter.Interpretations",
            prompt: FHIRPrompt.interpretation
        )
    }
    
    
    /// Interprets a given FHIR resource. Returns a human-readable interpretation.
    ///
    /// - Parameters:
    ///   - resource: The `FHIRResource` to be interpreted.
    ///   - forceReload: A boolean value that indicates whether to reload and reprocess the resource.
    /// - Returns: An asynchronous `String` representing the interpretation of the resource.
    @discardableResult
    public func interpret(resource: FHIRResource, forceReload: Bool = false) async throws -> String {
        try await resourceProcessor.process(resource: resource, forceReload: forceReload)
    }
    
    /// Retrieve the cached interpretation of a given FHIR resource. Returns a human-readable interpretation or `nil` if it is not present.
    ///
    /// - Parameter resource: The resource where the cached interpretation should be loaded from.
    /// - Returns: The cached interpretation. Returns `nil` if the resource is not present.
    public func cachedInterpretation(forResource resource: FHIRResource) -> String? {
        resourceProcessor.results[resource.id]
    }
    
    /// Adjust the LLM schema used by the ``FHIRResourceInterpreter``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    public func changeLLMSchema<Schema: LLMSchema>(to schema: Schema) {
        self.resourceProcessor.llmSchema = schema
    }
}


extension FHIRPrompt {
    /// Prompt used to interpret FHIR resources
    ///
    /// This prompt is used by the ``FHIRResourceInterpreter``.
    public static let interpretation: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.interpretation",
            localizedDescription: String(
                localized: "Interpretation Prompt",
                bundle: .module,
                comment: "Title of the interpretation prompt."
            ),
            defaultPrompt: String(
                localized: "Interpretation Prompt Content",
                bundle: .module,
                comment: "Content of the interpretation prompt."
            )
        )
    }()
}
