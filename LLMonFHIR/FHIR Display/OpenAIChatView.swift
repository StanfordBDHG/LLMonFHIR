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
    
    private let multipleResourceChat: Bool
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
                    if viewState == .idle && chat.last?.role != .assistant {
                        getAnswer()
                    }
                }
        }
    }
    
    init(chat: [Chat], title: String, multipleResourceChat: Bool) {
        
        self._chat = State(initialValue: chat)
        self.title = title
        self.multipleResourceChat = multipleResourceChat
    }
  
    private func getAnswer() {
        Task {
            do {
                viewState = .processing
                
                if multipleResourceChat {
                    try await processMultipleResourceChat()
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
    
    private func processMultipleResourceChat() async throws {
        let resourcesArray = await fhirStandard.resources
        var stringResourcesArray = resourcesArray.map { "\($0.displayName) in \($0.resourceType)" }
        stringResourcesArray.append("N/A")
        let functionCallOutputArray = try await getFunctionCallOutputArray(stringResourcesArray)
        if !functionCallOutputArray.contains(where: { $0.contains("N/A") }) {
            processFunctionCallOutputArray(functionCallOutputArray: functionCallOutputArray, resourcesArray: resourcesArray)
        }
    }

    private func getFunctionCallOutputArray(_ stringResourcesArray: [String]) async throws -> [String] {
        let openAI = OpenAI(apiToken: openAPIComponent.apiToken ?? "")
        
        let functions = [
            ChatFunctionDeclaration(
                name: "get_resource_titles",
                description: String(localized: "MULTIPLE_RESOURCE_FUNCTION_DESCRIPTION"),
                parameters: JSONSchema(
                    type: .object,
                    properties: [
                        "resources": .init(
                            type: .string,
                            description: String(localized: "MULTIPLE_RESOURCE_PARAMETER_DESCRIPTION"),
                            enumValues: stringResourcesArray
                        )
                    ],
                    required: ["resources"]
                )
            )
        ]

        let chat = [
            Chat(role: .user, content: chat.last?.content ?? ""),
            Chat(role: .system, content: String(localized: "MULTIPLE_RESOURCE_FUNCTION_CONTEXT") + stringResourcesArray.rawValue)
        ]
        
        let chatStreamResults = try await openAPIComponent.queryAPI(withChat: chat, withFunction: functions)

        class ChatFunctionCallBuilder {
            public var name: String?
            public var arguments: String?
            public var finishReason: String?
        }
        
        var functionCall = ChatFunctionCallBuilder()
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                if let delta = choice.delta.name {
                    functionCall.name = (functionCall.name ?? "") + delta
                }
                if let delta = choice.delta.functionCall?.arguments {
                    functionCall.arguments = (functionCall.arguments ?? "") + delta
                }
                if let finishReason = choice.finishReason {
                    functionCall.finishReason = (functionCall.finishReason ?? "") + finishReason
                    if finishReason == "get_resource_titles" {
                        break
                    }
                }
            }
        }
        
        var functionCallOutputArray = [String]()
        
        if functionCall.finishReason == "function_call" {
            let rawFunctionCallOutput = functionCall
            
            if let functionArguments = rawFunctionCallOutput.arguments {
                let trimmedFunctionArguments = functionArguments.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let resourcesRange = trimmedFunctionArguments.range(of: "\"resources\": \"([^\"]+)\"", options: .regularExpression) {
                    let trimmedResources = trimmedFunctionArguments[resourcesRange]
                    let resourcesString = trimmedResources
                        .replacingOccurrences(of: "\"resources\": \"", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                    let resourcesArray = resourcesString.components(separatedBy: ",")
                    
                    functionCallOutputArray = resourcesArray
                }
            }
        }
        
        return functionCallOutputArray
    }

    private func processFunctionCallOutputArray(functionCallOutputArray: [String], resourcesArray: [FHIRResource]) {
        let stringResourcesArray = resourcesArray.map { "\($0.displayName) in \($0.resourceType)" }
        for resource in functionCallOutputArray {
            var stringResource = resource
            stringResource = resource.trimmingCharacters(in: .whitespaces)
            print(stringResource)
            if let index = stringResourcesArray.firstIndex(of: stringResource) {
                let resourceJSON = resourcesArray[index].jsonDescription
                let functionContent = """
                Based on the function get_resource_titles you have requested the following health records: \(stringResource).
                This is the associated JSON data for the resources which you will use to answer the users question: \(resourceJSON).
                Use this health record to answer the users question ONLY IF the health record is applicable to the question.
                """
                chat.append(Chat(role: .function, content: functionContent, name: "get_resource_titles"))
            } else {
                print("Resource '\(resource)' not found in stringResourcesArray.")
            }
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
