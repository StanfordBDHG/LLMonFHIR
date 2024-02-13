//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage
import SwiftUI


class FHIRInterpretationModule: Module {
    @Dependency private var localStorage: LocalStorage
    @Dependency private var llmRunner: LLMRunner
    @Dependency private var fhirStore: FHIRStore
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    
    func configure() {
        let openAIModelType = UserDefaults.standard.string(forKey: StorageKeys.openAIModel) ?? StorageKeys.Defaults.openAIModel
        
        resourceSummary = FHIRResourceSummary(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: LLMOpenAISchema(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            )
        )
        
        resourceInterpreter = FHIRResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: LLMOpenAISchema(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            )
        )
        
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llmSchema: LLMOpenAISchema(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            ) {
                // FHIR interpretation function
                FHIRInterpretationFunction(
                    fhirStore: self.fhirStore,
                    resourceSummary: self.resourceSummary,
                    allResourcesFunctionCallIdentifier: self.fhirStore.allResourcesFunctionCallIdentifier
                )
            },
            fhirStore: fhirStore,
            resourceSummary: resourceSummary
        )
    }
}
