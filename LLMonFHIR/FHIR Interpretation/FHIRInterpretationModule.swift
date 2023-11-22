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
import class SpeziOpenAI.OpenAIModule
import class SpeziOpenAI.OpenAIModel


class FHIRInterpretationModule: Module {
    @Dependency private var localStorage: LocalStorage
    @Dependency private var openAI: OpenAIModule
    @StandardActor private var fhirStandard: FHIR
    
    @Model private var resourceSummary: FHIRResourceSummary
    @Model private var resourceInterpreter: FHIRResourceInterpreter
    @Model private var multipleResourceInterpreter: FHIRMultipleResourceInterpreter
    
    
    func configure() async {
        #warning("Will not work as this is actor isolated ...")
        resourceSummary = FHIRResourceSummary(localStorage: localStorage, openAIModel: openAI.model)
        resourceInterpreter = FHIRResourceInterpreter(localStorage: localStorage, openAIModel: openAI.model)
        multipleResourceInterpreter = await FHIRMultipleResourceInterpreter(
            localStorage: localStorage,
            openAIModel: openAI.model,
            fhirStore: fhirStandard.store
        )
    }
}
