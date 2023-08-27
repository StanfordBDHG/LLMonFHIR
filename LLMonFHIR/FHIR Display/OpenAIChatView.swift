//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import SpeziOpenAI
import SpeziViews
import SwiftUI


struct OpenAIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var openAPIComponent: OpenAIComponent
    @EnvironmentObject private var fhirStandard: FHIR
    
    @State private var chat: [Chat]
    @State private var viewState: ViewState = .idle
    @State private var systemFuncMessageAdded = false
    
    private let enableFunctionCalling: Bool
    private let title: String
    
    
    private var disableInput: Binding<Bool> {
        Binding(
            get: {
                viewState == .processing
            },
            set: { _ in }
        )
    }
    
    var body: some View {
        NavigationStack {
            ChatView($chat, disableInput: disableInput)
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("FHIR_RESOURCES_CHAT_CANCEL") {
                            dismiss()
                        }
                    }
                }
                .viewStateAlert(state: $viewState)
                .onChange(of: chat) { _ in
                    getAnswer()
                }
        }
    }
    
    
    init(chat: [Chat], title: String, enableFunctionCalling: Bool) {
        self._chat = State(initialValue: chat)
        self.title = title
        self.enableFunctionCalling = enableFunctionCalling
    }
    
    
    private func getAnswer() {
        guard viewState == .idle, chat.last?.role == .user else {
            return
        }
        
        Task {
            do {
                viewState = .processing
                
                if enableFunctionCalling {
                    if systemFuncMessageAdded == false {
                        try await addSystemFuncMessage()
                        systemFuncMessageAdded = true
                    }
                    try await processFunctionCalling()
                }
                
                try await processChatStreamResults()
                
                viewState = .idle
            } catch let error as APIErrorResponse {
                viewState = .error(error)
            } catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
    
    private func addSystemFuncMessage() async throws {
        let resourcesArray = await fhirStandard.resources
        
        var stringResourcesArray = resourcesArray.map { $0.functionCallIdentifier }
        stringResourcesArray.append("N/A")
        
        self.chat.append(Chat(role: .system, content: String(localized: "FUNCTION_CONTEXT") + stringResourcesArray.rawValue))
    }
    
    private func processFunctionCalling() async throws {
        let resourcesArray = await fhirStandard.resources
        
        var stringResourcesArray = resourcesArray.map { $0.functionCallIdentifier }
        stringResourcesArray.append("N/A")
        
        let functionCallOutputArray = try await getFunctionCallOutputArray(stringResourcesArray)
        
        processFunctionCallOutputArray(functionCallOutputArray: functionCallOutputArray, resourcesArray: resourcesArray)
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
        
        let chatStreamResults = try await openAPIComponent.queryAPI(withChat: chat, withFunction: functions)
        
        
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
    
    private func processFunctionCallOutputArray(functionCallOutputArray: [String], resourcesArray: [FHIRResource]) {
        for resource in functionCallOutputArray {
            guard let matchingResource = resourcesArray.first(where: { $0.functionCallIdentifier == resource }) else {
                continue
            }
            
            let functionContent = """
            Based on the function get_resource_titles you have requested the following health records: \(resource).
            This is the associated JSON data for the resources which you will use to answer the users question:
            \(matchingResource.jsonDescription)
            
            Use this health record to answer the users question ONLY IF the health record is applicable to the question.
            """
            
            chat.append(Chat(role: .function, content: functionContent, name: "get_resource_titles"))
        }
    }
    
    private func processChatStreamResults() async throws {
        let chatStreamResults = try await openAPIComponent.queryAPI(withChat: chat)
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                if chat.last?.role == .assistant {
                    let previousChatMessage = chat.last ?? Chat(role: .assistant, content: "")
                    chat[chat.count - 1] = Chat(
                        role: .assistant,
                        content: (previousChatMessage.content ?? "") + (choice.delta.content ?? "")
                    )
                } else {
                    chat.append(Chat(role: .assistant, content: choice.delta.content ?? ""))
                }
            }
        }
    }
}
