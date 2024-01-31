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
import class SpeziLLMOpenAI.LLMOpenAI
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
        let openAIModelType = UserDefaults.standard.string(forKey: StorageKeys.openAIModel) ?? .gpt4_1106_preview
        
        resourceSummary = FHIRResourceSummary(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llm: LLMOpenAI(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            )
        )
        
        resourceInterpreter = FHIRResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llm: LLMOpenAI(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            )
        )
        
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llm: LLMOpenAI(
                parameters: .init(
                    modelType: openAIModelType,
                    systemPrompt: nil   // No system prompt as this will be determined later by the resource interpreter
                )
            ),
            fhirStore: fhirStore,
            resourceSummary: resourceSummary
        )
    }
}
