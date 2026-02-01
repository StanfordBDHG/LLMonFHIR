//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Observation
import Spezi
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage


@Observable
final class FHIRInterpretationModule: Module, @unchecked Sendable {
    struct Config {
        static let `default` = Self(
            model: .gpt4o,
            temperature: 0,
            resourceLimit: nil,
            summarizeSingleResourcePrompt: .summarizeSingleFHIRResourceDefaultPrompt,
            systemPrompt: .interpretMultipleResourcesDefaultPrompt
        )
        
        let model: LLMOpenAIParameters.ModelType
        let temperature: Double
        let resourceLimit: Int
        let summarizeSingleResourcePrompt: FHIRPrompt
        let systemPrompt: FHIRPrompt
        
        init(
            model: LLMOpenAIParameters.ModelType,
            temperature: Double,
            resourceLimit: Int?,
            summarizeSingleResourcePrompt: FHIRPrompt,
            systemPrompt: FHIRPrompt
        ) {
            self.model = model
            self.temperature = temperature
            self.resourceLimit = resourceLimit ?? 250
            self.summarizeSingleResourcePrompt = summarizeSingleResourcePrompt
            self.systemPrompt = systemPrompt
        }
    }
    
    
    @ObservationIgnored @MainActor @Dependency(LocalStorage.self) private var localStorage: LocalStorage?
    @ObservationIgnored @MainActor @Dependency(LLMRunner.self) private var llmRunner
    @ObservationIgnored @MainActor @Dependency(FHIRStore.self) private var fhirStore
    
    // swiftlint:disable implicitly_unwrapped_optional
    @ObservationIgnored @MainActor private var resourceSummary: FHIRResourceSummary!
    @ObservationIgnored @MainActor private var resourceInterpreter: FHIRResourceInterpreter!
    @ObservationIgnored @MainActor private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter!
    // swiftlint:enable implicitly_unwrapped_optional
    
    @MainActor var config: Config?
    
    @ObservationIgnored private var updateModelsTask: Task<Void, any Error>?
    
    
    nonisolated init() {}
    
    @MainActor
    func configure() {
        self.resourceSummary = FHIRResourceSummary(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: singleResourceLLMSchema
        )
        
        self.resourceInterpreter = FHIRResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: singleResourceLLMSchema
        )
        
        self.multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: multipleResourceInterpreterOpenAISchema,
            fhirStore: fhirStore
        )
        
        // Double-check that we load the right configurations.
        Task {
            await updateSchemas()
        }
    }
    
    
    /// Updates the schema used by the interpretation module.
    ///
    /// By default, this function will delay the actual schema updating, in order to be able to coalesce multiple calls into just one update.
    ///
    /// - parameter forceImmediateUpdate: Set this to `true` to disable the delay and instead update the schema immediately.
    @MainActor
    func updateSchemas(forceImmediateUpdate: Bool = false) async {
        updateModelsTask?.cancel()
        let imp = { [self] in
            let summarizePrompt = config?.summarizeSingleResourcePrompt ?? .summarizeSingleFHIRResourceDefaultPrompt
            await resourceSummary.update(llmSchema: singleResourceLLMSchema, summarizationPrompt: summarizePrompt)
            await resourceInterpreter.update(llmSchema: singleResourceLLMSchema, summarizationPrompt: summarizePrompt)
            multipleResourceInterpreter.changeLLMSchema(
                to: multipleResourceInterpreterOpenAISchema,
                using: config?.systemPrompt ?? .interpretMultipleResourcesDefaultPrompt
            )
        }
        if forceImmediateUpdate {
            await imp()
        } else {
            updateModelsTask = Task {
                try? await Task.sleep(for: .seconds(0.1))
                if !Task.isCancelled {
                    await imp()
                }
            }
        }
    }
}


extension FHIRInterpretationModule {
    @MainActor var singleResourceLLMSchema: any LLMSchema {
        let config = config ?? .default
        return LLMOpenAISchema(
            parameters: .init(modelType: config.model.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: config.temperature)
        )
    }
    
    @MainActor var multipleResourceInterpreterOpenAISchema: LLMOpenAISchema {
        let config = config ?? .default
        return LLMOpenAISchema(
            parameters: .init(modelType: config.model.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: config.temperature)
        ) {
            FHIRGetResourceLLMFunction(
                fhirStore: fhirStore,
                resourceSummary: resourceSummary,
                resourceCountLimit: config.resourceLimit
            )
        }
    }
}
