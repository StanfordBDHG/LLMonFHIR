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


/// Responsible for summarizing FHIR resources.
@Observable
public final class FHIRResourceSummary: Sendable {
    /// Summary of a FHIR resource emitted by the ``FHIRResourceSummary``.
    public struct Summary: Codable, LosslessStringConvertible, Sendable {
        /// Title of the FHIR resource, should be shorter than 4 words.
        public let title: String
        /// Summary of the FHIR resource, should be a single line of text.
        public let summary: String
        
        
        public var description: String {
            title + "\n" + summary
        }
        
        
        public init?(_ description: String) {
            let components = description.split(separator: "\n")
            guard components.count == 2, let title = components.first, let summary = components.last else {
                return nil
            }
            
            self.title = String(title)
            self.summary = String(summary)
        }
    }
    
    
    private let resourceProcessor: FHIRResourceProcessor<Summary>
    
    
    /// - Parameters:
    ///   - localStorage: Local storage module that needs to be passed to the ``FHIRResourceSummary`` to allow it to cache summaries.
    ///   - openAIModel: OpenAI module that needs to be passed to the ``FHIRResourceSummary`` to allow it to retrieve summaries.
    public init(localStorage: LocalStorage, llmRunner: LLMRunner, llmSchema: any LLMSchema) {
        self.resourceProcessor = FHIRResourceProcessor(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: llmSchema,
            storageKey: "FHIRResourceSummary.Summaries",
            prompt: FHIRPrompt.summary
        )
    }
    
    
    /// Summarizes a given FHIR resource. Returns a human-readable summary.
    ///
    /// - Parameters:
    ///   - resource: The `FHIRResource` to be summarized.
    ///   - forceReload: A boolean value that indicates whether to reload and reprocess the resource.
    /// - Returns: An asynchronous `String` representing the summarization of the resource.
    @discardableResult
    public func summarize(resource: FHIRResource, forceReload: Bool = false) async throws -> Summary {
        try await resourceProcessor.process(resource: resource, forceReload: forceReload)
    }
    
    /// Retrieve the cached summary of a given FHIR resource. Returns a human-readable summary or `nil` if it is not present.
    ///
    /// - Parameter resource: The resource where the cached summary should be loaded from.
    /// - Returns: The cached summary. Returns `nil` if the resource is not present.
    public func cachedSummary(forResource resource: FHIRResource) -> Summary? {
        resourceProcessor.results[resource.id]
    }
    
    /// Adjust the LLM schema used by the ``FHIRResourceSummary``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    public func changeLLMSchema<Schema: LLMSchema>(to schema: Schema) {
        self.resourceProcessor.llmSchema = schema
    }
}


extension FHIRPrompt {
    /// Prompt used to summarize FHIR resources
    ///
    /// This prompt is used by the ``FHIRResourceSummary``.
    public static let summary: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.summary",
            localizedDescription: String(
                localized: "Summary Prompt",
                bundle: .module,
                comment: "Title of the summary prompt."
            ),
            defaultPrompt: String(
                localized: "Summary Prompt Content",
                bundle: .module,
                comment: "Content of the summary prompt."
            )
        )
    }()
}
