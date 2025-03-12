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
final class FHIRResourceSummary: Sendable {
    /// Summary of a FHIR resource emitted by the ``FHIRResourceSummary``.
    struct Summary: Codable, LosslessStringConvertible, Sendable {
        /// Title of the FHIR resource, should be shorter than 4 words.
        let title: String
        /// Summary of the FHIR resource, should be a single line of text.
        let summary: String
        
        
        var description: String {
            title + "\n" + summary
        }
        
        
        init?(_ description: String) {
            let lines = description
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard !lines.isEmpty else {
                return nil
            }

            if lines.count == 1 {
                let wordCount = lines[0]
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .count

                if wordCount <= 4 {
                    self.title = lines[0]
                    self.summary = "No detailed summary available"
                } else {
                    let words = lines[0]
                        .components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                    self.title = words
                        .prefix(3)
                        .joined(separator: " ")
                    self.summary = lines[0]
                }
            } else {
                self.title = lines[0]
                self.summary = lines
                    .dropFirst()
                    .joined(separator: " ")
            }

            guard !self.title.isEmpty && !self.summary.isEmpty else {
                return nil
            }
        }
    }
    
    
    private let resourceProcessor: FHIRResourceProcessor<Summary>
    
    
    /// - Parameters:
    ///   - localStorage: Local storage module that needs to be passed to the ``FHIRResourceSummary`` to allow it to cache summaries.
    ///   - openAIModel: OpenAI module that needs to be passed to the ``FHIRResourceSummary`` to allow it to retrieve summaries.
    init(localStorage: LocalStorage, llmRunner: LLMRunner, llmSchema: any LLMSchema) {
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
    func summarize(resource: FHIRResource, forceReload: Bool = false) async throws -> Summary {
        let resource = try resource.copy()
        try? resource.stringifyAttachements()
        return try await resourceProcessor.process(resource: resource, forceReload: forceReload)
    }
    
    /// Retrieve the cached summary of a given FHIR resource. Returns a human-readable summary or `nil` if it is not present.
    ///
    /// - Parameter resource: The resource where the cached summary should be loaded from.
    /// - Returns: The cached summary. Returns `nil` if the resource is not present.
    func cachedSummary(forResource resource: FHIRResource) -> Summary? {
        resourceProcessor.results[resource.id]
    }
    
    /// Adjust the LLM schema used by the ``FHIRResourceSummary``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    func changeLLMSchema<Schema: LLMSchema>(to schema: Schema) {
        self.resourceProcessor.llmSchema = schema
    }
}


extension FHIRPrompt {
    /// Prompt used to summarize FHIR resources
    ///
    /// This prompt is used by the ``FHIRResourceSummary``.
    static let summary: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.summary",
            localizedDescription: String(
                localized: "SUMMARY_PROMPT",
                bundle: .main
            ),
            defaultPrompt: String(
                localized: "SUMMARY_PROMPT_CONTENT_OPENAI",
                bundle: .main
            )
        )
    }()
}
