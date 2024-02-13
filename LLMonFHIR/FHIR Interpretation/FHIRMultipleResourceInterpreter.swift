//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os
import Spezi
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage
import SpeziViews
import SwiftUI


private enum FHIRMultipleResourceInterpreterConstants {
    static let chat = "FHIRMultipleResourceInterpreter.chat"
}


@Observable
class FHIRMultipleResourceInterpreter {
    static let logger = Logger(subsystem: "edu.stanford.bdhg", category: "LLMonFHIR")
    
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private let llmSchema: any LLMSchema
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    var llm: (any LLMSession)?
    
    
    required init(
        localStorage: LocalStorage,
        llmRunner: LLMRunner,
        llmSchema: any LLMSchema,
        fhirStore: FHIRStore,
        resourceSummary: FHIRResourceSummary
    ) {
        self.localStorage = localStorage
        self.llmRunner = llmRunner
        self.llmSchema = llmSchema
        self.fhirStore = fhirStore
        self.resourceSummary = resourceSummary
    }
    
    
    @MainActor
    func resetChat() {
        llm?.context = []
        queryLLM()
    }

    @MainActor
    func queryLLM() {
        guard llm?.context.last?.role == .user || !(llm?.context.contains(where: { $0.role == .assistant }) ?? false) else {
            return
        }
        
        Task {
            var llm: LLMSession
            if let llmTemp = self.llm {
                llm = llmTemp
            } else {
                llm = await llmRunner(with: llmSchema)
                self.llm = llm
            }
            
            if llm.context.isEmpty {
                llm.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
            }
            
            if let patient = fhirStore.patient {
                llm.context.append(systemMessage: patient.jsonDescription)
            }
            
            Self.logger.debug("The Multiple Resource Interpreter has access to \(self.fhirStore.llmRelevantResources.count) resources.")
            
            guard let stream = try? await llm.generate() else {
                return
            }
            
            for try await token in stream {
                llm.context.append(assistantOutput: token)
            }
            
            try localStorage.store(llm.context, storageKey: FHIRMultipleResourceInterpreterConstants.chat)
        }
    }
}


extension FHIRPrompt {
    /// Prompt used to interpret multple FHIR resources
    ///
    /// This prompt is used by the ``FHIRMultipleResourceInterpreter``.
    public static let interpretMultipleResources: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.interpretMultipleResources",
            localizedDescription: String(
                localized: "Interpretation Prompt",
                comment: "Title of the multiple resources interpretation prompt."
            ),
            defaultPrompt: String(
                localized: "Interpretation Prompt Content",
                comment: "Content of the multiple resources interpretation prompt."
            )
        )
    }()
}
