//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage
import SwiftUI


// periphery:ignore - Properties are used through dependency injection and @Model configuration in `configure()`
class FHIRInterpretationModule: Module, DefaultInitializable, EnvironmentAccessible {
    @Dependency(LocalStorage.self) private var localStorage
    @Dependency(LLMRunner.self) private var llmRunner
    @Dependency(FHIRStore.self) private var fhirStore
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    
    @MainActor var simpleOpenAISchema: LLMOpenAISchema {
        let openAIModelType = StorageKeys.currentOpenAIModel
        let temperature = StorageKeys.currentOpenAIModelTemperature
        
        return LLMOpenAISchema(
            parameters: .init(modelType: openAIModelType.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: temperature)
        )
    }
    
    @MainActor var multipleResourceInterpreterOpenAISchema: LLMOpenAISchema {
        let openAIModelType = StorageKeys.currentOpenAIModel
        let temperature = StorageKeys.currentOpenAIModelTemperature
        let resourceLimit = StorageKeys.currentResourceCountLimit
        
        return LLMOpenAISchema(
            parameters: .init(modelType: openAIModelType.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: temperature)
        ) {
            FHIRGetResourceLLMFunction(
                fhirStore: self.fhirStore,
                resourceSummary: self.resourceSummary,
                resourceCountLimit: resourceLimit
            )
        }
    }
    
    
    required init() {}
    
    
    func configure() {
        resourceSummary = FHIRResourceSummary(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: simpleOpenAISchema
        )
        
        resourceInterpreter = FHIRResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: simpleOpenAISchema
        )
        
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
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
    
    
    @MainActor
    func updateSchemas() async {
        await resourceSummary.changeLLMSchema(to: simpleOpenAISchema)
        await resourceInterpreter.changeLLMSchema(to: simpleOpenAISchema)
        multipleResourceInterpreter.changeLLMSchema(to: multipleResourceInterpreterOpenAISchema)
    }
}
