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
    
    
    private var functions: [ChatFunctionDeclaration] {
        [LLMFunction.getResources(allResourcesFunctionCallIdentifier: fhirStore.allResourcesFunctionCallIdentifier)]
    }
    
    
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
                        Chat(
                            role: .system,
                            content: FHIRPrompt.interpretation.prompt
                        ),
                        Chat(
                            role: .system,
                            content: String(
                                localized: "Content of the function context passed to the LLM",
                                comment: "The list of possible titles will be appended to the end of this prompt."
                            ) + fhirStore.allResourcesFunctionCallIdentifier.rawValue
                        )
                    ]
                }
                
                try await executeLLMQueries()
                
                try localStorage.store(chat, storageKey: FHIRMultipleResourceInterpreterConstants.chat)
                
                viewState = .idle
            } catch let error as APIErrorResponse {
                viewState = .error(error)
            } catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
    
    private func executeLLMQueries() async throws {
        while true {
            let chatStreamResults = try await openAIModel.queryAPI(withChat: chat, withFunction: functions)
            
            let currentMessageCount = chat.count
            var llmStreamResults: [LLMStreamResult] = []
            
            for try await chatStreamResult in chatStreamResults {
                // Parse the different elements in mutable llm stream results.
                for choice in chatStreamResult.choices {
                    let existingLLMStreamResult = llmStreamResults.first(where: { $0.id == choice.index })
                    let llmStreamResult: LLMStreamResult
                    
                    if let existingLLMStreamResult {
                        llmStreamResult = existingLLMStreamResult
                    } else {
                        llmStreamResult = LLMStreamResult(id: choice.index)
                        llmStreamResults.append(llmStreamResult)
                    }
                    
                    llmStreamResult.append(choice: choice)
                }
                
                // Append assistant messages during the streaming to ensure that they are presented in the UI.
                // Limitation: We currently don't really handle multiple llmStreamResults, messages could overwritten.
                for llmStreamResult in llmStreamResults where llmStreamResult.role == .assistant && !(llmStreamResult.content?.isEmpty ?? true) {
                    let newMessage = Chat(
                        role: .assistant,
                        content: llmStreamResult.content
                    )
                    
                    if chat.indices.contains(currentMessageCount) {
                        chat[currentMessageCount] = newMessage
                    } else {
                        chat.append(newMessage)
                    }
                }
            }
            
            let functionCalls = llmStreamResults.compactMap { $0.functionCall }
            
            // Exit the while loop if we don't have any function calls.
            guard !functionCalls.isEmpty else {
                break
            }
            
            for functionCall in functionCalls {
                print("Function Call - Name: \(functionCall.name ?? ""), Arguments: \(functionCall.arguments ?? "")")
                
                switch functionCall.name {
                case LLMFunction.getResourcesName:
                    callGetResources(functionCall: functionCall)
                default:
                    break
                }
            }
        }
    }
    
    
    private func callGetResources(functionCall: LLMStreamResult.FunctionCall) {
        struct Response: Codable {
            let resources: String
        }
            
        guard let jsonData = functionCall.arguments?.data(using: .utf8),
              let response = try? JSONDecoder().decode(Response.self, from: jsonData) else {
            return
        }
        
        let requestedResources = response.resources.filter { !$0.isWhitespace }.components(separatedBy: ",")
        
        print("Parsed Resources: \(requestedResources)")
        
        for requestedResource in requestedResources {
            for resource in fhirStore.allResources.filter({ $0.functionCallIdentifier == requestedResource }) {
                print("Appending Resource: \(resource)")
                chat.append(
                    Chat(
                        role: .function,
                        content: String(localized: "This is the content of the requested \(requestedResource):\n\n\(resource.jsonDescription)"),
                        name: LLMFunction.getResourcesName
                    )
                )
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
