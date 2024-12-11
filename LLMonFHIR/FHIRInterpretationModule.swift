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


public class FHIRInterpretationModule: Module, DefaultInitializable {
    public enum Defaults {
        public static var llmSchema: LLMOpenAISchema {
            .init(
                parameters: .init(
                    modelType: .gpt4_turbo,
                    systemPrompts: []   // No system prompt as this will be determined later by the resource interpreter
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
    
    let summaryLLMSchema: any LLMSchema
    let interpretationLLMSchema: any LLMSchema
    let openAIModelType: LLMOpenAIModelType
    let resourceCountLimit: Int
    let allowedResourcesFunctionCallIdentifiers: Set<String>?   // swiftlint:disable:this discouraged_optional_collection
    
    
    /// - Warning: Ensure that passed LLM schema's don't contain a system prompt! This will be configured by the ``FHIRInterpretationModule``.
    public init<SummaryLLM: LLMSchema, InterpretationLLM: LLMSchema>(
        summaryLLMSchema: SummaryLLM = Defaults.llmSchema,
        interpretationLLMSchema: InterpretationLLM = Defaults.llmSchema,    // swiftlint:disable:this function_default_parameter_at_end
        multipleResourceInterpretationOpenAIModel: LLMOpenAIModelType,  // swiftlint:disable:this identifier_name
        resourceCountLimit: Int = 250,
        allowedResourcesFunctionCallIdentifiers: Set<String>? = nil // swiftlint:disable:this discouraged_optional_collection
    ) {
        self.summaryLLMSchema = summaryLLMSchema
        self.interpretationLLMSchema = interpretationLLMSchema
        self.openAIModelType = multipleResourceInterpretationOpenAIModel
        self.resourceCountLimit = resourceCountLimit
        self.allowedResourcesFunctionCallIdentifiers = allowedResourcesFunctionCallIdentifiers
    }
    
    
    public required convenience init() {
        self.init(
            summaryLLMSchema: Defaults.llmSchema,
            interpretationLLMSchema: Defaults.llmSchema,
            multipleResourceInterpretationOpenAIModel: .gpt4_turbo
        )
    }
    
    
    public func configure() {
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
            llmSchema: LLMOpenAISchema(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompts: []   // No system prompt as this will be determined later by the resource interpreter
                )
            ) {
                // FHIR interpretation function
                FHIRGetResourceLLMFunction(
                    fhirStore: self.fhirStore,
                    resourceSummary: self.resourceSummary,
                    resourceCountLimit: self.resourceCountLimit,
                    allowedResourcesFunctionCallIdentifiers: self.allowedResourcesFunctionCallIdentifiers
                )
            },
            fhirStore: fhirStore
        )
    }
}
