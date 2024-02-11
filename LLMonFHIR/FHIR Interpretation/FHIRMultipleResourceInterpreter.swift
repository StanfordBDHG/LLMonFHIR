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
import SpeziViews
import SwiftUI


private enum FHIRMultipleResourceInterpreterConstants {
    static let chat = "FHIRMultipleResourceInterpreter.chat"
}


@Observable
class FHIRMultipleResourceInterpreter {
    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private let llmSchema: any LLMSchema
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    @MainActor var viewState: ViewState = .idle
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
        guard viewState == .idle, llm?.context.last?.role == .user || !(llm?.context.contains(where: { $0.role == .assistant }) ?? false) else {
            return
        }
        
        Task {
            do {
                var llm: LLMSession
                if let llmTemp = self.llm {
                    llm = llmTemp
                } else {
                    llm = await llmRunner(with: llmSchema)
                    self.llm = llm
                }
                
                viewState = .processing
                
                if llm.context.isEmpty {
                    llm.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
                }
                
                if let patient = fhirStore.patient {
                    llm.context.append(systemMessage: patient.jsonDescription)
                }
                
                print("The Multiple Resource Interpreter has access to \(fhirStore.llmRelevantResources.count) resources.")
                
                do {
                    let stream = try await llm.generate()
                    
                    for try await token in stream {
                        llm.context.append(assistantOutput: token)
                    }
                } catch let error as LLMError {
                    llm.state = .error(error: error)
                } catch {
                    llm.state = .error(error: LLMDefaultError.unknown(error))
                }
                
                try localStorage.store(llm.context, storageKey: FHIRMultipleResourceInterpreterConstants.chat)
                
                viewState = .idle
            } catch {
                viewState = .error(error.localizedDescription)
            }
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
