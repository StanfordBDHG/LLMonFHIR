//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Foundation
public import SpeziChat


extension Bundle {
    /// The `LLMonFHIR` module's Bundle.
    public static var llmOnFhirShared: Bundle {
        .module
    }
}


extension ChatEntity.Role {
    public var rawValue: String {
        switch self {
        case .user:
            "user"
        case .assistant:
            "assistant"
        case .assistantToolCall:
            "assistant_tool_call"
        case .assistantToolResponse:
            "assistant_tool_response"
        case .hidden(let type):
            "hidden_\(type.name)"
        }
    }
}
