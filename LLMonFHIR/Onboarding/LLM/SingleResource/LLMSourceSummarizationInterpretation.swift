//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2024 Stanford University & Project Contributors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM
import SpeziLLMFog
import SpeziLLMLocal
import SpeziLLMOpenAI


/// Important: These models will only be used for the summarization and interpretation LLM tasks, not the multiple resource chat
enum LLMSourceSummarizationInterpretation: CaseIterable, Identifiable, Codable, RawRepresentable, Hashable {
    case local
    case fog
    case openAi(LLMOpenAIModelType)
    
    
    static var allCases: [LLMSourceSummarizationInterpretation] = [.local, .fog, .openAi(.gpt4_turbo_preview)]
    
    
    var id: String {
        self.rawValue
    }
    
    var rawValue: String {
        self.localizedDescription.localizedString()
    }
    
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .local:
            LocalizedStringResource("LOCAL_LLM_LABEL")
        case .fog:
            LocalizedStringResource("FOG_LLM_LABEL")
        case .openAi:
            LocalizedStringResource("OPENAI_LLM_LABEL")
        }
    }
    
    var llmSchema: any LLMSchema {
        switch self {
        case .local:
            LLMLocalSchema(
                modelPath: .cachesDirectory.appending(path: "llm.gguf"),
                parameters: .init(systemPrompt: nil)
            )
        case .fog:
            LLMFogSchema(
                parameters: .init(modelType: .llama7B, systemPrompt: nil, authToken: { nil })
            )
        case .openAi(let modelType):
            LLMOpenAISchema(
                parameters: .init(
                    modelType: modelType,
                    systemPrompt: nil
                )
            )
        }
    }
    
    
    init?(rawValue: String) {
        switch rawValue {
        case LocalizedStringResource("LOCAL_LLM_LABEL").localizedString(): self = .local
        case LocalizedStringResource("FOG_LLM_LABEL").localizedString(): self = .fog
        case LocalizedStringResource("OPENAI_LLM_LABEL").localizedString(): self = .openAi(.gpt4_turbo_preview)
        default: return nil
        }
    }
}
