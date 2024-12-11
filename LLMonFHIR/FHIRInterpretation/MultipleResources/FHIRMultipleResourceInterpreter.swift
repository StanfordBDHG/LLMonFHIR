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
public class FHIRMultipleResourceInterpreter {
    static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")
    
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private var llmSchema: any LLMSchema
    private let fhirStore: FHIRStore
    
    var llm: (any LLMSession)?
    
    
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
    }
    
    
    @MainActor
    func resetChat() {
        llm = llmRunner(with: llmSchema)
        llm?.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
        if let patient = fhirStore.patient {
            llm?.context.append(systemMessage: patient.jsonDescription)
        }
    }
    
    @MainActor
    func prepareLLM() async {
        guard llm == nil else {
            return
        }
        
        let llm = llmRunner(with: llmSchema)
        // Read initial conversation from storage
        if let storedContext: LLMContext = try? localStorage.read(storageKey: FHIRMultipleResourceInterpreterConstants.context) {
            llm.context = storedContext
        } else {
            llm.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
            if let patient = fhirStore.patient {
                llm.context.append(systemMessage: patient.jsonDescription)
            }
        }

        self.llm = llm
    }

    @MainActor
    func queryLLM() {
        guard let llm,
              llm.context.last?.role == .user || !(llm.context.contains(where: { $0.role == .assistant() }) ) else {
            return
        }
        
        Task {
            Self.logger.debug("The Multiple Resource Interpreter has access to \(self.fhirStore.llmRelevantResources.count) resources.")
            
            guard let stream = try? await llm.generate() else {
                return
            }
            
            for try await token in stream {
                llm.context.append(assistantOutput: token)
            }
            
            // Store conversation to storage
            try localStorage.store(llm.context, storageKey: FHIRMultipleResourceInterpreterConstants.context)
        }
    }
    
    /// Change the `LLMSchema` used by the ``FHIRMultipleResourceInterpreter``.
    @MainActor
    public func changeLLMSchema(
        openAIModel model: LLMOpenAIModelType,
        resourceCountLimit: Int,
        resourceSummary: FHIRResourceSummary,
        allowedResourcesFunctionCallIdentifiers: Set<String>? = nil // swiftlint:disable:this discouraged_optional_collection
    ) {
        self.llmSchema = LLMOpenAISchema(
            parameters: .init(
                modelType: model,
                systemPrompts: []   // No system prompt as this will be determined later by the resource interpreter
            )
        ) {
            // FHIR interpretation function
            FHIRGetResourceLLMFunction(
                fhirStore: self.fhirStore,
                resourceSummary: resourceSummary,
                resourceCountLimit: resourceCountLimit,
                allowedResourcesFunctionCallIdentifiers: allowedResourcesFunctionCallIdentifiers
            )
        }
        self.llm = nil
        
        Task {
            await prepareLLM()
        }
    }
}


extension FHIRPrompt {
    /// Prompt used to interpret multiple FHIR resources
    ///
    /// This prompt is used by the ``FHIRMultipleResourceInterpreter``.
    public static let interpretMultipleResources: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.interpretMultipleResources",
            localizedDescription: String(
                localized: "Interpretation Prompt",
                bundle: .module,
                comment: "Title of the multiple resources interpretation prompt."
            ),
            defaultPrompt: String(
                localized: "Multiple Resource Interpretation Prompt Content",
                bundle: .module,
                comment: "Content of the multiple resources interpretation prompt."
            )
        )
    }()
}
