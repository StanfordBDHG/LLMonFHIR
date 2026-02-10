//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import Spezi
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI


final class SessionCoordinator: Module, @unchecked Sendable {
    struct Config: Sendable {
        let model: LLMOpenAIParameters.ModelType
        let temperature: Double
        let resourceLimit: Int
        let summarizeSingleResourcePrompt: FHIRPrompt
        let systemPrompt: FHIRPrompt
    }
    
    @MainActor @Dependency(FHIRStore.self) var fhirStore
    @MainActor @Dependency(LLMRunner.self) private var llmRunner
    
    // swiftlint:disable implicitly_unwrapped_optional
    @MainActor private(set) var resourceSummarizer: FHIRResourceSummarizer!
    @MainActor private var singleResourceInterpreter: SingleFHIRResourceInterpreter!
    @MainActor private(set) var multipleResourceInterpreter: FHIRMultipleResourceInterpreter!
    // swiftlint:enable implicitly_unwrapped_optional
    
    /// The immutable config of the session.
    private let config: Config
    
    nonisolated init(config: Config) {
        self.config = config
    }
    
    @MainActor
    func configure() {
        resourceSummarizer = FHIRResourceSummarizer(
            localStorage: nil,
            llmRunner: llmRunner,
            llmSchema: singleResourceLLMSchema
        )
        singleResourceInterpreter = SingleFHIRResourceInterpreter(
            localStorage: nil,
            llmRunner: llmRunner,
            llmSchema: singleResourceLLMSchema
        )
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: nil,
            llmRunner: llmRunner,
            llmSchema: multipleResourceInterpreterOpenAISchema,
            fhirStore: fhirStore
        )
        // NOTE: intentionally not calling updateSchema/prepareForUse here;
        // the CLI tool is responsible for doing this before performing any chat interactions
    }
    
    
    /// Updates the schema used by the interpretation module.
    ///
    /// - Important: This function must be called before any chat interactions are performed.
    @MainActor
    func prepareForUse() async {
        let summarizePrompt = config.summarizeSingleResourcePrompt
        await resourceSummarizer.update(llmSchema: singleResourceLLMSchema, summarizationPrompt: summarizePrompt)
        await singleResourceInterpreter.update(llmSchema: singleResourceLLMSchema, summarizationPrompt: summarizePrompt)
        multipleResourceInterpreter.changeLLMSchema(
            to: multipleResourceInterpreterOpenAISchema,
            using: config.systemPrompt
        )
    }
}


extension SessionCoordinator {
    private var singleResourceLLMSchema: any LLMSchema {
        LLMOpenAISchema(
            parameters: .init(modelType: config.model.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: config.temperature)
        )
    }
    
    @MainActor private var multipleResourceInterpreterOpenAISchema: LLMOpenAISchema {
        LLMOpenAISchema(
            parameters: .init(modelType: config.model.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: config.temperature)
        ) {
            FHIRGetResourceLLMFunction(
                fhirStore: fhirStore,
                resourceSummarizer: resourceSummarizer,
                resourceCountLimit: config.resourceLimit
            )
        }
    }
}
