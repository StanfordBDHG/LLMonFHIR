//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOpenAI
import SwiftUI


struct OpenAIChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var openAPIComponent: OpenAIComponent<FHIR>

    @State var chat: [Chat]
    @State var gettingAnswer = false
    
    let title: String
    

    var body: some View {
        NavigationStack {
            ChatView($chat, disableInput: $gettingAnswer)
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("FHIR_RESOURCES_CHAT_CANCEL") {
                            dismiss()
                        }
                    }
                }
                .onChange(of: chat) { _ in
                    if !gettingAnswer {
                        getAnswer()
                    }
                }
        }
    }
    
    
    private func getAnswer() {
        Task {
            do {
                gettingAnswer = true
                
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
                
                gettingAnswer = false
            } catch {
                print(error)
            }
            gettingAnswer = false
        }
    }
}
