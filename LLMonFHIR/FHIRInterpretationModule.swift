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
import SpeziLLMLocal
import SpeziLLMOpenAI
import SpeziLocalStorage
import SwiftUI


public class FHIRInterpretationModule: Module, DefaultInitializable {
    public enum Defaults {
        public static var llmOpenAISchema: LLMOpenAISchema {
            .init(
                parameters: .init(
                    modelType: .gpt4_turbo_preview,
                    systemPrompts: []   // No system prompt as this will be determined later by the resource interpreter
                )
            )
        }
        
        public static let multipleResourceInterpretationAIModel = InterpretationModelType.openAI(.gpt4_o)
        
        public static var llmLocalSchema: LLMLocalSchema {
            .init(
                model: .custom(id: "mlx-community/OpenHermes-2.5-Mistral-7B-4bit-mlx"),
                parameters: .init(systemPrompt: "You are a helpful assistant who will always answer the question with only the data provided.")
            )
        }
    }
    
    
    @Dependency private var localStorage: LocalStorage
    @Dependency private var llmRunner: LLMRunner
    @Dependency private var fhirStore: FHIRStore
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    let summaryLLMSchema: any LLMSchema
    let interpretationLLMSchema: any LLMSchema
    let interpreationModelType: InterpretationModelType
    let resourceCountLimit: Int
    let allowedResourcesFunctionCallIdentifiers: Set<String>?   // swiftlint:disable:this discouraged_optional_collection
    
    
    /// - Warning: Ensure that passed LLM schema's don't contain a system prompt! This will be configured by the ``FHIRInterpretationModule``.
    public init<SummaryLLM: LLMSchema, InterpretationLLM: LLMSchema>(
        summaryLLMSchema: SummaryLLM,
        interpretationLLMSchema: InterpretationLLM,
        multipleResourceInterpretationAIModel: InterpretationModelType,
        resourceCountLimit: Int = 250,
        allowedResourcesFunctionCallIdentifiers: Set<String>? = nil // swiftlint:disable:this discouraged_optional_collection
    ) {
        self.summaryLLMSchema = summaryLLMSchema
        self.interpretationLLMSchema = interpretationLLMSchema
        self.interpreationModelType = multipleResourceInterpretationAIModel
        self.resourceCountLimit = resourceCountLimit
        self.allowedResourcesFunctionCallIdentifiers = allowedResourcesFunctionCallIdentifiers
    }
    
    
    public required convenience init() {
        self.init(
            summaryLLMSchema: Defaults.llmOpenAISchema,
            interpretationLLMSchema: Defaults.llmOpenAISchema,
            multipleResourceInterpretationAIModel: Defaults.multipleResourceInterpretationAIModel
        )
    }
    
    
    public func configure() {
        resourceSummary = FHIRResourceSummary(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: summaryLLMSchema,
            prompt: FHIRPrompt.summaryLocalLLM
        )
        
        resourceInterpreter = FHIRResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: interpretationLLMSchema
        )
        
        let schema: any LLMSchema = switch interpreationModelType {
        case .openAI(let modelType):
            LLMOpenAISchema(
                parameters: .init(
                    modelType: modelType,
                    systemPrompts: []
                )
            ) {
                // FHIR interpretation function
                FHIRGetResourceLLMFunction(
                    fhirStore: self.fhirStore,
                    resourceSummary: self.resourceSummary,
                    resourceCountLimit: self.resourceCountLimit,
                    allowedResourcesFunctionCallIdentifiers: self.allowedResourcesFunctionCallIdentifiers
                )
            }
        case .local(let modelType):
            fatalError("Not implemented")
        }
        
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: schema,
            fhirStore: fhirStore
        )
    }
}
