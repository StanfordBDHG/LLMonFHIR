//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
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
    static let context = "FHIRMultipleResourceInterpreter.userStudy.context"
}


/// Used to interpret multiple FHIR resources via a chat-based interface with an LLM.
@Observable
class UserStudyFHIRMultipleResourceInterpreter {
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
            try localStorage.store(llm.context, for: .init(FHIRMultipleResourceInterpreterConstants.context))
        }
    }
}
