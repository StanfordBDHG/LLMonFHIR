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
    let fhirStore: FHIRStore

    private var currentGenerationTask: Task<LLMContextEntity?, Never>?

    /// The current LLM session managing the conversation context with the language model.
    ///
    /// This property holds the active conversation session, including system prompts,
    /// user inputs, and assistant responses. Changes to this property will be reflected in the UI.
    private(set) var llmSession: any LLMSession


    /// Initializes a new FHIR resource interpreter with the provided dependencies.
    ///
    /// This initializer sets up a new interpreter, either restoring a previous conversation
    /// from persistent storage or creating a new conversation with system prompts.
    ///
    /// - Parameters:
    ///   - localStorage: Storage provider for persisting conversation between sessions
    ///   - llmRunner: Factory for creating LLM sessions
    ///   - llmSchema: Configuration that defines how the LLM responds
    ///   - fhirStore: Provider of FHIR resources to be interpreted
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

    /// Starts a new conversation by creating a fresh LLM session.
    ///
    /// This  creates an entirely new session and replaces the current one.
    func startNewConversation() {
        let newLLMSession = llmRunner(with: llmSchema)
        newLLMSession.context = createInterpretationContext()
        do {
            try localStorage.delete(.init(FHIRMultipleResourceInterpreterConstants.context))
            Self.logger.debug("Deleted previous conversation context from storage")
        } catch {
            Self.logger.error("Failed to delete conversation context: \(error)")
        }
        llmSession = newLLMSession
        Self.logger.debug("Created new LLM session with fresh context")
    }

    /// Generates an assistant response based on the current conversation context.
    ///
    /// - Returns: The last `LLMContextEntity` representing the completed assistant response,
    ///   or `nil` if generation was cancelled or encountered an error.
    func generateAssistantResponse() async -> LLMContextEntity? {
        currentGenerationTask?.cancel()
        currentGenerationTask = Task { [weak self] in
            guard let self else {
                return nil
            }
            defer {
                currentGenerationTask = nil
            }
            Self.logger.debug("The Multiple Resource Interpreter has access to \(self.fhirStore.llmRelevantResources.count) resources.")
            do {
                let stream = try await llmSession.generate()
                for try await token in stream {
                    try Task.checkCancellation()
                    llmSession.context.append(assistantOutput: token)
                }
                try Task.checkCancellation()
                llmSession.context.completeAssistantStreaming()
                try localStorage.store(llmSession.context, for: .init(FHIRMultipleResourceInterpreterConstants.context))
                Self.logger.debug("Successfully stored updated conversation context")
                return llmSession.context.last
            } catch is CancellationError {
                Self.logger.error("Response generation was cancelled")
                return nil
            } catch {
                Self.logger.error("Error during response generation: \(error.localizedDescription)")
                return nil
            }
        }
        return await currentGenerationTask?.value
    }

    /// Updates the LLM schema used by the interpreter.
    ///
    /// This method changes the underlying LLM schema, which affects how future
    /// responses are generated. It creates a new session with the updated schema
    /// and initializes it with basic system prompts.
    ///
    /// - Parameter newSchema: The new schema to use for future conversations.
    ///                       This must conform to the `LLMSchema` protocol.
    ///
    /// After calling this method, any new responses will be generated using the new schema,
    /// but the conversation will start fresh with only system messages.
    func changeLLMSchema(to newSchema: some LLMSchema) {
        Self.logger.debug("Updating LLM schema")
        self.llmSchema = newSchema
        let newSession = llmRunner(with: llmSchema)
        Self.logger.debug("Setting up new conversation with updated schema")
        newSession.context = createInterpretationContext()
        llmSession = newSession
    }

    /// Cancels any ongoing response generation.
    ///
    /// This method immediately stops the current generation task if one is in progress.
    /// Use this when you need to interrupt response generation.
    func cancel() {
        currentGenerationTask?.cancel()
    }

    private func createInterpretationContext() -> LLMContext {
        var context = LLMContext()
        context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
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
