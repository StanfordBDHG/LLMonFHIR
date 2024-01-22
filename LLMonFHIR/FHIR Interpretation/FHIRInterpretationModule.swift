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
import SpeziLocalStorage
import SpeziLLM
import SpeziLLMOpenAI


class FHIRInterpretationModule: Module {
    @Dependency private var localStorage: LocalStorage
    @Dependency private var llmRunner: LLMRunner
    @Dependency private var fhirStore: FHIRStore
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    
    func configure() {
        resourceSummary = FHIRResourceSummary(localStorage: localStorage, openAIModel: openAI.model)
        resourceInterpreter = FHIRResourceInterpreter(localStorage: localStorage, openAIModel: openAI.model)
        multipleResourceInterpreter = FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            llmRunner: llmRunner,
            llm: LLMOpenAI(parameters: .init(modelType: .gpt4_1106_preview), {
                // TODO: Code change in SpeziLLM to enable default value
            }),
            fhirStore: fhirStore,
            resourceSummary: resourceSummary
        )
    }
}
