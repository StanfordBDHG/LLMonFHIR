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


class FHIRResourceProcessor<Content: Codable & LosslessStringConvertible> {
    typealias Results = [FHIRResource.ID: Content]
    
    
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private let storageKey: String
    private let prompt: FHIRPrompt
    private let lock = NSLock()
    var llmSchema: any LLMSchema
    
    
    var results: Results = [:] {
        didSet {
            do {
                try localStorage.store(results, storageKey: storageKey)
            } catch {
                print(error)
            }
        }
    }
    
    
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
        self.results = (try? localStorage.read(storageKey: storageKey)) ?? [:]
    }
    
    
    @discardableResult
    func process(resource: FHIRResource, forceReload: Bool = false) async throws -> Content {
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
        
        lock.withLock {
            results[resource.id] = content
        }
        
        return content
    }
}
