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
import SpeziFoundation
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage


// Unchecked `Sendable` conformance is fine as mutable storage (results & _llmSchema) is guarded by the `RWLock`.
final class FHIRResourceProcessor<Content: Codable & LosslessStringConvertible>: @unchecked Sendable {
    typealias Results = [FHIRResource.ID: Content]
    
    
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private let storageKey: String
    private let prompt: FHIRPrompt
    private let lock = RWLock()
    
    private let resultsLock = RWLock()
    private(set) var results: Results = [:] {
        didSet {
            lock.withReadLock {
                try? localStorage.store(results, for: .init(storageKey))
            }
        }
    }
    
    private let llmSchemaLock = RWLock()
    private var _llmSchema: any LLMSchema
    
    
    var llmSchema: any LLMSchema {
        get {
            llmSchemaLock.withReadLock {
                _llmSchema
            }
        }
        set {
            llmSchemaLock.withWriteLock {
                _llmSchema = newValue
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
        self._llmSchema = llmSchema
        self.storageKey = storageKey
        self.prompt = prompt
        self.results = (try? localStorage.load(.init(storageKey))) ?? [:]
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
        
        lock.withWriteLock {
            results[resource.id] = content
        }
        
        return content
    }
}
