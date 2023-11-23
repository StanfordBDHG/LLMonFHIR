//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import Spezi
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziLocalStorage
import SpeziOpenAI
import SpeziViews
import SwiftUI


private enum FHIRMultipleResourceInterpreterConstants {
    static let chat = "FHIRMultipleResourceInterpreter.chat"
}


@Observable
class FHIRMultipleResourceInterpreter {
    private let localStorage: LocalStorage
    private let openAIModel: OpenAIModel
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    var chat: [Chat] = []
    var viewState: ViewState = .idle
    
    
    required init(localStorage: LocalStorage, openAIModel: OpenAIModel, fhirStore: FHIRStore, resourceSummary: FHIRResourceSummary) {
        self.localStorage = localStorage
        self.openAIModel = openAIModel
        self.fhirStore = fhirStore
        self.resourceSummary = resourceSummary
        
        chat = (try? localStorage.read(storageKey: FHIRMultipleResourceInterpreterConstants.chat)) ?? []
    }
    
    
    func resetChat() {
        chat = []
        queryLLM()
    }
    
    func queryLLM() {
        guard viewState == .idle, chat.last?.role == .user || !chat.contains(where: { $0.role == .assistant }) else {
            return
        }
        
        Task {
            do {
                viewState = .processing
                
                if chat.isEmpty {
                    chat = [
                        systemPrompt(forResources: fhirStore.allResources),
                        Chat(role: .system, content: String(localized: "FUNCTION_CONTEXT") + fhirStore.allResourcesFunctionCallIdentifier.rawValue)
                    ]
                }
                
                try await processFunctionCalling()
                try await processChatStreamResults()
                
                try localStorage.store(chat, storageKey: FHIRMultipleResourceInterpreterConstants.chat)
                
                viewState = .idle
            } catch let error as APIErrorResponse {
                viewState = .error(error)
            } catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
    
    private func systemPrompt(forResources resources: [FHIRResource]) -> Chat {
        var resourceCategories = String()
        
        for resource in resources {
            resourceCategories += (resource.functionCallIdentifier + "\n")
        }
        
        return Chat(
            role: .system,
            content: FHIRPrompt.interpretMultipleResources.prompt(withFHIRResource: resourceCategories)
        )
    }
    
    private func processFunctionCalling() async throws {
        let functionCallOutputArray = try await getFunctionCallOutputArray(fhirStore.allResourcesFunctionCallIdentifier)
        await processFunctionCallOutputArray(functionCallOutputArray: functionCallOutputArray)
    }
    
    private func getFunctionCallOutputArray(_ stringResourcesArray: [String]) async throws -> [String] {
        let functions = [
            ChatFunctionDeclaration(
                name: "get_resource_titles",
                description: String(localized: "FUNCTION_DESCRIPTION"),
                parameters: JSONSchema(
                    type: .object,
                    properties: [
                        "resources": .init(type: .string, description: String(localized: "PARAMETER_DESCRIPTION"), enumValues: stringResourcesArray)
                    ],
                    required: ["resources"]
                )
            )
        ]
        
        let chatStreamResults = try await openAIModel.queryAPI(withChat: chat, withFunction: functions)
        
        
        class ChatFunctionCall {
            var name: String = ""
            var arguments: String = ""
            var finishReason: String = ""
        }
        
        let functionCall = ChatFunctionCall()
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                if let deltaName = choice.delta.name {
                    functionCall.name += deltaName
                }
                if let deltaArguments = choice.delta.functionCall?.arguments {
                    functionCall.arguments += deltaArguments
                }
                if let finishReason = choice.finishReason {
                    functionCall.finishReason += finishReason
                    if finishReason == "get_resource_titles" { break }
                }
            }
        }
        
        guard functionCall.finishReason == "function_call" else {
            return []
        }
        
        let trimmedArguments = functionCall.arguments.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let resourcesRange = trimmedArguments.range(of: "\"resources\": \"([^\"]+)\"", options: .regularExpression) else {
            return []
        }
        
        return trimmedArguments[resourcesRange]
            .replacingOccurrences(of: "\"resources\": \"", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .components(separatedBy: ",")
    }
    
    private func processFunctionCallOutputArray(functionCallOutputArray: [String]) async {
        for resource in functionCallOutputArray {
            guard let matchingResource = fhirStore.allResources.first(where: { $0.functionCallIdentifier == resource }) else {
                continue
            }
            
            guard let resourceDescription = try? await resourceSummary.summarize(resource: matchingResource) else {
                continue
            }
            
            let functionContent = """
            This is the description of the following resource: \(resource).
            Use this health record to answer the users question ONLY IF the health record is applicable to the question.
            
            \(resourceDescription)
            """
            
            chat.append(Chat(role: .function, content: functionContent, name: "get_resource_titles"))
        }
    }
    
    private func processChatStreamResults() async throws {
        let chatStreamResults = try await openAIModel.queryAPI(withChat: chat)
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                guard let newContent = choice.delta.content else {
                    continue
                }
                
                if chat.last?.role == .assistant, let previousContent = chat.last?.content {
                    chat[chat.count - 1] = Chat(
                        role: .assistant,
                        content: previousContent + newContent
                    )
                } else {
                    chat.append(Chat(role: .assistant, content: newContent))
                }
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
