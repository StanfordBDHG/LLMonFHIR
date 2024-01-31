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
    private let fhirStore: FHIRStore
    private let resourceSummary: FHIRResourceSummary
    
    @MainActor var viewState: ViewState = .idle
    var llm: any LLM
    
    
    required init(localStorage: LocalStorage, llmRunner: LLMRunner, llm: any LLM, fhirStore: FHIRStore, resourceSummary: FHIRResourceSummary) {
        self.localStorage = localStorage
        self.llmRunner = llmRunner
        self.llm = llm
        self.fhirStore = fhirStore
        self.resourceSummary = resourceSummary
        
        Task { @MainActor in
            llm.context = (try? localStorage.read(storageKey: FHIRMultipleResourceInterpreterConstants.chat)) ?? []
        }
    }
    
    
    @MainActor
    func resetChat() {
        llm.context = []
        queryLLM()
    }
    
    // TODO: Can we get rid of this main actor annotation?
    @MainActor
    func queryLLM() {
        guard viewState == .idle, llm.context.last?.role == .user || !llm.context.contains(where: { $0.role == .assistant }) else {
            return
        }
        
        Task {
            do {
                viewState = .processing
                
                if llm.context.isEmpty {
                    llm.context.append(systemMessage: FHIRPrompt.interpretMultipleResources.prompt)
                }
                
                if let patient = fhirStore.patient {
                    llm.context.append(systemMessage: patient.jsonDescription)
                }
                
                print("The Multiple Resource Interpreter has access to \(fhirStore.llmRelevantResources.count) resources.")
                
                //try await executeLLMQueries()
                do {
                    let stream = try await llmRunner(with: llm).generate()
                    
                    for try await token in stream {
                        llm.context.append(assistantOutput: token)
                    }
                } catch let error as LLMError {
                    llm.state = .error(error: error)
                } catch {
                    llm.state = .error(error: LLMRunnerError.setupError)
                }
                
                try localStorage.store(llm.context, storageKey: FHIRMultipleResourceInterpreterConstants.chat)
                
                viewState = .idle
            } 
            /*  Do we need something like that?
            catch let error as APIErrorResponse {
                viewState = .error(error)
            }
             */
            catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
    
    /*
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
                    try await callGetResources(functionCall: functionCall)
                default:
                    break
                }
            }
        }
    }
    
    
    private func callGetResources(functionCall: LLMStreamResult.FunctionCall) async throws {
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
            var fittingResources = fhirStore.llmRelevantResources.filter { $0.functionCallIdentifier.contains(requestedResource) }
            
            guard !fittingResources.isEmpty else {
                chat.append(
                    Chat(
                        role: .function,
                        content: String(localized: "The medical record does not include any FHIR resources for the search term \(requestedResource)."),
                        name: LLMFunction.getResourcesName
                    )
                )
                continue
            }
            
            print("Fitting Resources: \(fittingResources.count)")
            if fittingResources.count > 64 {
                fittingResources = fittingResources.lazy.sorted(by: { $0.date ?? .distantPast < $1.date ?? .distantPast }).suffix(64)
                print("Reduced to the following 64 resources: \(fittingResources.map { $0.functionCallIdentifier }.joined(separator: ","))")
            }
            
            for resource in fittingResources {
                print("Appending Resource: \(resource)")
                let summary = try await resourceSummary.summarize(resource: resource)
                print("Summary of Resource generated: \(summary)")
                chat.append(
                    Chat(
                        role: .function,
                        content: String(localized: "This is the summary of the requested \(requestedResource):\n\n\(summary.description)"),
                        name: LLMFunction.getResourcesName
                    )
                )
            }
        }
    }
     */
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
