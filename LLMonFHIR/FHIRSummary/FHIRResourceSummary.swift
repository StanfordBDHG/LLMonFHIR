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
    /// Error thrown when summarization fails.
    enum SummaryError: Error {
        case summaryFailed(String)
    }

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
            let lines = description.components(separatedBy: "\n")
            let nonEmptyLines = lines.filter { !$0.isEmpty }

            switch nonEmptyLines.count {
            case 0:
                return nil
            case 1:
                title = nonEmptyLines[0]
                summary = nonEmptyLines[0]
            default:
                title = nonEmptyLines[0]
                summary = nonEmptyLines.dropFirst().joined(separator: "\n")
            }
        }
    }
    
    
    private let resourceProcessor: FHIRResourceProcessor<Summary>
    private let maxRetries = 1


    /// - Parameters:
    ///   - localStorage: Local storage module that needs to be passed to the ``FHIRResourceSummary`` to allow it to cache summaries.
    ///   - llmRunner: OpenAI module that needs to be passed to the ``FHIRResourceSummary`` to allow it to retrieve summaries.
    ///   - llmSchema: LLM schema to use for generating summaries.
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
    func summarize(resource: SendableFHIRResource, forceReload: Bool = false) async throws -> Summary {
        try? resource.stringifyAttachments()

        var retryCount = 0
        var summary: Summary?

        repeat {
            summary = try await resourceProcessor.process(resource: resource, forceReload: forceReload || retryCount > 0)
            retryCount += 1

            guard summary == nil else {
                break
            }

            try? await Task.sleep(for: .seconds(0.1))
        } while retryCount < maxRetries

        guard let summary = summary else {
            throw SummaryError.summaryFailed("Failed to generate valid summary after \(maxRetries) retries")
        }

        return summary
    }
    
    /// Retrieve the cached summary of a given FHIR resource. Returns a human-readable summary or `nil` if it is not present.
    ///
    /// - Parameter resource: The resource where the cached summary should be loaded from.
    /// - Returns: The cached summary. Returns `nil` if the resource is not present.
    func cachedSummary(forResource resource: FHIRResource) async -> Summary? {
        await resourceProcessor.results[resource.id]
    }
    
    /// Adjust the LLM schema used by the ``FHIRResourceSummary``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    func changeLLMSchema(to schema: some LLMSchema) async {
        await resourceProcessor.changeSchema(to: schema)
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
