//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os
import Spezi
import SpeziChat
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI
import SpeziLocalStorage
import SpeziViews
import SwiftUI


private enum FHIRMultipleResourceInterpreterConstants {
    static let context = "FHIRMultipleResourceInterpreter.context"
}


/// Used to interpret multiple FHIR resources via a chat-based interface with an LLM.
@Observable
class FHIRMultipleResourceInterpreter {
    static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")
    
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private var llmSchema: any LLMSchema
    private let fhirStore: FHIRStore
    
    var llm: any LLMSession
    var viewState: ViewState = .idle
    
    
    required init(
        localStorage: LocalStorage,
        llmRunner: LLMRunner,
        llmSchema: any LLMSchema,
        fhirStore: FHIRStore
    ) {
        self.localStorage = localStorage
        self.llmRunner = llmRunner
        self.llmSchema = llmSchema
        self.fhirStore = fhirStore
        self.llm = llmRunner(with: llmSchema)
        
        Task { @MainActor in
            await prepareLLM()
        }
    }
    
    
    @MainActor
    func resetChat() {
        viewState = .processing
        llm = llmRunner(with: llmSchema)
        llm.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
        if let patient = fhirStore.patient {
            llm.context.append(systemMessage: patient.jsonDescription)
        }
        viewState = .idle
    }
    
    @MainActor
    func prepareLLM() async {
        viewState = .processing
        let llm = llmRunner(with: llmSchema)
        // Read initial conversation from storage
        if let storedContext: LLMContext = try? localStorage.load(.init(FHIRMultipleResourceInterpreterConstants.context)) {
            llm.context = storedContext
        } else {
            llm.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
            if let patient = fhirStore.patient {
                llm.context.append(systemMessage: patient.jsonDescription)
            }
        }

        self.llm = llm
        viewState = .idle
    }

    @MainActor
    func queryLLM() {
        guard llm.context.last?.role == .user || !(llm.context.contains(where: { $0.role == .assistant() }) ) else {
            return
        }
        
        viewState = .processing
        
        Task {
            do {
                defer {
                    viewState = .idle
                }
                
                Self.logger.debug("The Multiple Resource Interpreter has access to \(self.fhirStore.llmRelevantResources.count) resources.")
                
                let stream = try await llm.generate()
                
                for try await token in stream {
                    llm.context.append(assistantOutput: token)
                }
                
                // Store conversation to storage
                try localStorage.store(llm.context, for: .init(FHIRMultipleResourceInterpreterConstants.context))
            } catch {
                viewState = .error(AnyLocalizedError(error: error))
            }
        }
    }
    
    /// Adjust the LLM schema used by the ``FHIRMultipleResourceInterpreter``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    func changeLLMSchema<Schema: LLMSchema>(to schema: Schema) {
        self.llmSchema = schema
        
        Task {
            await prepareLLM()
        }
    }
}


extension FHIRPrompt {
    /// Prompt used to interpret multiple FHIR resources
    ///
    /// This prompt is used by the ``FHIRMultipleResourceInterpreter``.
    static let interpretMultipleResources: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.interpretMultipleResources",
            localizedDescription: String(
                localized: "Interpretation Prompt",
                bundle: .main,
                comment: "Title of the multiple resources interpretation prompt."
            ),
            defaultPrompt: String(
                localized: "Multiple Resource Interpretation Prompt Content",
                bundle: .main,
                comment: "Content of the multiple resources interpretation prompt."
            )
        )
    }()
}
