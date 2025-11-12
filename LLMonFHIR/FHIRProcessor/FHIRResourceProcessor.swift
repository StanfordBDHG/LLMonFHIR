//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziChat
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage


actor FHIRResourceProcessor<Content: Codable & LosslessStringConvertible> {
    typealias Results = [FHIRResource.ID: Content]
    
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private let storageKey: String
    private let prompt: FHIRPrompt
    
    private(set) var results: Results = [:] {
        didSet {
            try? localStorage.store(results, for: .init(storageKey))
        }
    }
    
    private(set) var llmSchema: any LLMSchema
    
    init(
        localStorage: LocalStorage,
        llmRunner: LLMRunner,
        llmSchema: any LLMSchema,
        storageKey: String,
        prompt: FHIRPrompt
    ) {
        self.localStorage = localStorage
        self.llmRunner = llmRunner
        self.llmSchema = llmSchema
        self.storageKey = storageKey
        self.prompt = prompt
        self.results = (try? localStorage.load(.init(storageKey))) ?? [:]
    }
    
    
    func changeSchems(to schema: any LLMSchema) {
        self.llmSchema = schema
    }
    
    @discardableResult
    func process(resource: SendableFHIRResource, forceReload: Bool = false) async throws -> Content {
        if let result = results[resource.id], !result.description.isEmpty, !forceReload {
            return result
        }
        let chatStreamResult: String = try await llmRunner.oneShot(
            with: llmSchema,
            context: .init(systemMessages: [prompt.prompt(withFHIRResource: resource.jsonDescription)])
        )
        guard let content = Content(chatStreamResult) else {
            throw FHIRResourceProcessorError.notParsableAsAString
        }
        results[resource.id] = content
        return content
    }
}
