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
class FHIRInterpretationModule: Module, DefaultInitializable {
    enum Defaults {
        static var llmSchema: LLMOpenAISchema {
            .init(
                parameters: .init(
                    modelType: .gpt4o,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            )
        }
    }
    
    
    @Dependency(LocalStorage.self) private var localStorage
    @Dependency(LLMRunner.self) private var llmRunner
    @Dependency(FHIRStore.self) private var fhirStore
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    @Model private var multipleResourceInterpreterUserStudy: UserStudyFHIRMultipleResourceInterpreter

    @AppStorage(StorageKeys.openAIModelTemperature) private var openAIModelTemperature = StorageKeys.Defaults.openAIModelTemperature

    let summaryLLMSchema: any LLMSchema
    let interpretationLLMSchema: any LLMSchema
    let openAIModelType: LLMOpenAIParameters.ModelType
    let resourceCountLimit: Int
    let allowedResourcesFunctionCallIdentifiers: Set<String>?   // swiftlint:disable:this discouraged_optional_collection
    
    
    /// - Warning: Ensure that passed LLM schema's don't contain a system prompt! This will be configured by the ``FHIRInterpretationModule``.
    init<SummaryLLM: LLMSchema, InterpretationLLM: LLMSchema>(
        summaryLLMSchema: SummaryLLM = Defaults.llmSchema,
        interpretationLLMSchema: InterpretationLLM = Defaults.llmSchema,    // swiftlint:disable:this function_default_parameter_at_end
        multipleResourceInterpretationOpenAIModel: LLMOpenAIParameters.ModelType,  // swiftlint:disable:this identifier_name
        resourceCountLimit: Int = 250,
        allowedResourcesFunctionCallIdentifiers: Set<String>? = nil // swiftlint:disable:this discouraged_optional_collection
    ) {
        self.summaryLLMSchema = summaryLLMSchema
        self.interpretationLLMSchema = interpretationLLMSchema
        self.openAIModelType = multipleResourceInterpretationOpenAIModel
        self.resourceCountLimit = resourceCountLimit
        self.allowedResourcesFunctionCallIdentifiers = allowedResourcesFunctionCallIdentifiers
    }
    
    
    required convenience init() {
        self.init(
            summaryLLMSchema: Defaults.llmSchema,
            interpretationLLMSchema: Defaults.llmSchema,
            multipleResourceInterpretationOpenAIModel: .gpt4o
        )
    }
    
    
    func configure() {
        resourceSummary = FHIRResourceSummary(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: summaryLLMSchema
        )
        
        resourceInterpreter = FHIRResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: interpretationLLMSchema
        )
        
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: createOpenAISchema(),
            fhirStore: fhirStore
        )
        
        multipleResourceInterpreterUserStudy = UserStudyFHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: createOpenAISchema(),
            fhirStore: fhirStore
        )
    }

    @MainActor
    private func createOpenAISchema() -> LLMOpenAISchema {
        LLMOpenAISchema(
            parameters: .init(
                modelType: openAIModelType.rawValue,
                systemPrompts: []
            ),
            modelParameters: .init(temperature: openAIModelTemperature)
        ) {
            // FHIR interpretation function
            FHIRGetResourceLLMFunction(
                fhirStore: self.fhirStore,
                resourceSummary: self.resourceSummary,
                resourceCountLimit: self.resourceCountLimit,
                allowedResourcesFunctionCallIdentifiers: self.allowedResourcesFunctionCallIdentifiers
            )
        }
    }
}
