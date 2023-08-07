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
    @EnvironmentObject private var openAPIComponent: OpenAIComponent<FHIR>

    @State private var chat: [Chat]
    @State private var viewState: ViewState = .idle
    
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
                    if viewState == .idle && chat.last?.role == .user {
                        getAnswer()
                    }
                }
        }
    }
    
    
    init(chat: [Chat], title: String) {
        self._chat = State(initialValue: chat)
        self.title = title
    }
    
    
    private func getAnswer() {
        Task {
            do {
                viewState = .processing
                
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
                
                viewState = .idle
            } catch let error as APIErrorResponse {
                viewState = .error(error)
            } catch {
                viewState = .error(error.localizedDescription)
            }
        }
    }
}
