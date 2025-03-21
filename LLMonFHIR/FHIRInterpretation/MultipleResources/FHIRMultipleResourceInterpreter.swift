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
    static let context = "FHIRMultipleResourceInterpreter.context"
}


/// Used to interpret multiple FHIR resources via a chat-based interface with an LLM.
///
/// This class facilitates conversations with a large language model about FHIR healthcare data.
/// It manages the conversation context, handles generating responses based on available FHIR resources,
/// and persists conversation state between sessions.
@Observable
@MainActor
final class FHIRMultipleResourceInterpreter {
    static let logger = Logger(subsystem: "edu.stanford.spezi.fhir", category: "SpeziFHIRLLM")

    private let localStorage: LocalStorage
    private let llmRunner: LLMRunner
    private var llmSchema: any LLMSchema
    private let fhirStore: FHIRStore

    private var currentGenerationTask: Task<Void, Never>?

    /// The current LLM session managing the conversation context with the language model.
    ///
    /// This property holds the active conversation session, including system prompts,
    /// user inputs, and assistant responses. Changes to this property will be reflected in the UI.
    private(set) var llmSession: any LLMSession

    var chatBinding: Binding<Chat> {
        Binding(
            get: { [weak self] in
                self?.llmSession.context.chat ?? []
            },
            set: { [weak self] newChat in
                self?.updateChat(newChat)
            }
        )
    }


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
        self.llmSession = llmRunner(with: llmSchema)

        if let storedContext: LLMContext = try? localStorage.load(.init(FHIRMultipleResourceInterpreterConstants.context)) {
            llmSession.context = storedContext
            Self.logger.debug("Restored previous conversation context")
        } else {
            Self.logger.debug("Setting up new conversation context")
            llmSession.context = createInterpretationContext()
        }
    }

    private func updateChat(_ newChat: Chat) {
        llmSession.context.chat = newChat
    }

    /// Starts a new conversation, discarding the previous context.
    ///
    /// This method:
    /// - Attempts to delete any previously stored conversation context
    /// - Creates a fresh LLM session with the current schema
    /// - Initializes the session with appropriate system prompts and patient data
    ///
    /// Use this method when you want to completely reset the conversation history
    /// and begin a new dialogue with the LLM.
    func startNewConversation() {
        do {
            try localStorage.delete(.init(FHIRMultipleResourceInterpreterConstants.context))
            Self.logger.debug("Deleted previous conversation context")
        } catch {
            Self.logger.error("Failed to delete conversation context: \(error)")
        }

        let newSession = llmRunner(with: llmSchema)
        newSession.context = createInterpretationContext()
        llmSession = newSession
    }

    /// Generates an assistant response based on the current conversation context.
    ///
    /// The generated response will be automatically appended to the conversation context
    /// and will be observable through the `llmSession` property.
    func generateAssistantResponse() {
        guard llmSession.context.last?.role == .user || !(llmSession.context.contains(where: { $0.role == .assistant() }) ) else {
            Self.logger.debug("Not generating response - no user message or assistant already responded")
            return
        }

        currentGenerationTask?.cancel()

        currentGenerationTask = Task {
            defer {
                currentGenerationTask = nil
            }

            Self.logger.debug("The Multiple Resource Interpreter has access to \(self.fhirStore.llmRelevantResources.count) resources.")

            do {
                let stream = try await llmSession.generate()

                for try await token in stream {
                    if Task.isCancelled {
                        Self.logger.debug("Response generation was cancelled")
                        break
                    }
                    llmSession.context.append(assistantOutput: token)
                }

                try localStorage.store(llmSession.context, for: .init(FHIRMultipleResourceInterpreterConstants.context))

                Self.logger.debug("Successfully stored updated conversation context")
            } catch {
                Self.logger.error("Error during response generation: \(error.localizedDescription)")
            }
        }
    }

    /// Updates the LLM schema used by the interpreter.
    ///
    /// This method changes the underlying LLM schema, which affects how future
    /// responses are generated while attempting to preserve the existing conversation context.
    ///
    /// - Parameter newSchema: The new schema to use for future conversations.
    ///                       This must conform to the `LLMSchema` protocol.
    ///
    /// After calling this method, any new responses will be generated using the new schema,
    /// but the conversation history will be maintained if possible.
    func updateLLMSchema<Schema: LLMSchema>(to newSchema: Schema) {
        Self.logger.debug("Updating LLM schema")
        self.llmSchema = newSchema

        let newSession = llmRunner(with: llmSchema)

        if let storedContext: LLMContext = try? localStorage.load(.init(FHIRMultipleResourceInterpreterConstants.context)) {
            newSession.context = storedContext
            Self.logger.debug("Restored conversation context with new schema")
        } else {
            Self.logger.debug("Setting up new conversation with updated schema")
            newSession.context = createInterpretationContext()
        }

        llmSession = newSession
    }

    /// Cancels any ongoing response generation.
    ///
    /// This method immediately stops the current generation task if one is in progress.
    func cancel() {
        currentGenerationTask?.cancel()
    }

    private func createInterpretationContext() -> LLMContext {
        var context = LLMContext()
        context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
        if let patient = fhirStore.patient {
            context.append(systemMessage: patient.jsonDescription)
        }
        return context
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
