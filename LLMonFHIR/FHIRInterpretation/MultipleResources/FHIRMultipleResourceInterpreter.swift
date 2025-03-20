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
@MainActor
class FHIRMultipleResourceInterpreter {
    static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")

    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private var llmSchema: any LLMSchema
    private let fhirStore: FHIRStore
    private var activeTask: Task<Void, Never>?

    var llm: any LLMSession

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
    }
    
    

    func resetChat() {
        cancelOngoingTasks()

        let newLLM = llmRunner(with: llmSchema)
        newLLM.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
        if let patient = fhirStore.patient {
            newLLM.context.append(systemMessage: patient.jsonDescription)
        }
        llm = newLLM
    }

    func prepareLLM() {
        cancelOngoingTasks()

        let newLLM = llmRunner(with: llmSchema)

        if let storedContext: LLMContext = try? localStorage.load(.init(FHIRMultipleResourceInterpreterConstants.context)) {
            newLLM.context = storedContext
        } else {
            newLLM.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
            if let patient = fhirStore.patient {
                newLLM.context.append(systemMessage: patient.jsonDescription)
            }
        }

        llm = newLLM
    }

    func queryLLM() {
        guard llm.context.last?.role == .user || !(llm.context.contains(where: { $0.role == .assistant() })) else {
            return
        }

        cancelOngoingTasks()

        activeTask = Task {
            do {
                Self.logger.debug("The Multiple Resource Interpreter has access to \(self.fhirStore.llmRelevantResources.count) resources.")

                let stream = try await llm.generate()

                for try await token in stream {
                    if Task.isCancelled {
                        break
                    }
                    llm.context.append(assistantOutput: token)
                }

                if !Task.isCancelled {
                    try localStorage.store(llm.context, for: .init(FHIRMultipleResourceInterpreterConstants.context))
                }
            } catch {
                if !Task.isCancelled {
                    //
                }
            }
        }
    }

    /// Adjust the LLM schema used by the ``FHIRMultipleResourceInterpreter``.
    ///
    /// - Parameters:
    ///    - schema: The to-be-used `LLMSchema`.
    func changeLLMSchema<Schema: LLMSchema>(to schema: Schema) {
        llmSchema = schema
        prepareLLM()
    }

    /// Cancels any ongoing LLM operations
    func cancelOngoingTasks() {
        activeTask?.cancel()
        activeTask = nil
    }

    /// Cleanup resources and cancel operations
    func cancel() {
        cancelOngoingTasks()
        llm.cancel()
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
