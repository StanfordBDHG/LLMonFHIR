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
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI
import SpeziLocalStorage
import SpeziViews
import SwiftUI


// periphery:ignore - Properties are used through dependency injection and @Model configuration in `configure()`
final class FHIRInterpretationModule: Module, DefaultInitializable, EnvironmentAccessible {
    @Dependency(LocalStorage.self) private var localStorage
    @Dependency(LLMRunner.self) private var llmRunner
    @Dependency(FHIRStore.self) private var fhirStore
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    @LocalPreference(.llmSource) private var llmSource
    @LocalPreference(.openAIModel) private var openAIModel
    @LocalPreference(.openAIModelTemperature) private var openAIModelTemperature
    @LocalPreference(.fogModel) private var fogModel
    @LocalPreference(.resourceLimit) private var resourceLimit
    
    
    @MainActor var singleResourceLLMSchema: any LLMSchema {
        switch self.llmSource {
        case .openai:
            LLMOpenAISchema(
                parameters: .init(modelType: openAIModel.rawValue, systemPrompts: []),
                modelParameters: .init(temperature: openAIModelTemperature)
            )
        case .fog:
            LLMFogSchema(
                parameters: .init(modelType: fogModel)
            )
        case .local:
            LLMLocalSchema(
                model: .llama3_2_3B_4bit // always use the Llama 3.2 3B model as we can guarantee that it runs well on modern devices
            )
        }
    }
    
    @MainActor var multipleResourceInterpreterOpenAISchema: LLMOpenAISchema {
        LLMOpenAISchema(
            parameters: .init(modelType: openAIModel.rawValue, systemPrompts: []),
            modelParameters: .init(temperature: openAIModelTemperature)
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
    
    
    @MainActor
    func updateSchemas() async {
        await resourceSummary.changeLLMSchema(to: singleResourceLLMSchema)
        await resourceInterpreter.changeLLMSchema(to: singleResourceLLMSchema)
        multipleResourceInterpreter.changeLLMSchema(to: multipleResourceInterpreterOpenAISchema)
    }
}
