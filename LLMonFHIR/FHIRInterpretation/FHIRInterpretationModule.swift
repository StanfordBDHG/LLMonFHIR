//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import Spezi
import SpeziFHIR
import SpeziFoundation
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI
import SpeziLocalStorage
import SwiftUI


// periphery:ignore - Properties are used through dependency injection and @Model configuration in `configure()`
@Observable
final class FHIRInterpretationModule: Module, EnvironmentAccessible, @unchecked Sendable {
    @ObservationIgnored @MainActor @Dependency(LocalStorage.self) private var localStorage
    @ObservationIgnored @MainActor @Dependency(LLMRunner.self) private var llmRunner
    @ObservationIgnored @MainActor @Dependency(FHIRStore.self) private var fhirStore
    
    @ObservationIgnored @MainActor @Model private var resourceSummary: FHIRResourceSummary
    @ObservationIgnored @MainActor @Model private var resourceInterpreter: FHIRResourceInterpreter
    @ObservationIgnored @MainActor @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    @ObservationIgnored @LocalPreference(.llmSource) private var llmSource
    @ObservationIgnored @LocalPreference(.openAIModel) private var openAIModel
    @ObservationIgnored @LocalPreference(.openAIModelTemperature) private var openAIModelTemperature
    @ObservationIgnored @LocalPreference(.fogModel) private var fogModel
    @ObservationIgnored @LocalPreference(.resourceLimit) private var resourceLimit
    
    @MainActor var currentStudy: Study? {
        didSet {
            Task {
                await updateSchemas(forceImmediateUpdate: true)
            }
        }
    }
    
    @ObservationIgnored private var updateModelsTask: Task<Void, any Error>?
    
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
            let summarizePrompt = currentStudy?.summarizeSingleResourcePrompt ?? .summarizeSingleFHIRResourceDefaultPrompt
            await resourceSummary.update(llmSchema: singleResourceLLMSchema, summarizationPrompt: summarizePrompt)
            await resourceInterpreter.update(llmSchema: singleResourceLLMSchema, summarizationPrompt: summarizePrompt)
            multipleResourceInterpreter.changeLLMSchema(to: multipleResourceInterpreterOpenAISchema, for: currentStudy)
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
