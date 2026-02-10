//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziLLM


extension UserStudyChatViewModel {
    enum ProcessingState: Equatable {
        case processingSystemPrompts
        case processingFunctionCalls(currentCall: Int, totalCalls: Int)
        case generatingResponse
        case completed
        case error
        
        var progress: Double {
            switch self {
            case .processingSystemPrompts:
                return 10
            case let .processingFunctionCalls(current, total):
                let functionCallProgress = total > 0 ? Double(current) / Double(total) : 0
                return 20 + functionCallProgress * 70
            case .generatingResponse:
                return 90
            case .completed:
                return 100
            case .error:
                return 0
            }
        }
        
        var statusDescription: String {
            switch self {
            case .processingSystemPrompts:
                "Interpreting message..."
            case let .processingFunctionCalls(current, total):
                "Processing data (\(current)/\(total))..."
            case .generatingResponse:
                "Generating response..."
            case .completed:
                "Processing completed"
            case .error:
                "Encountered an error"
            }
        }
        
        var isProcessing: Bool {
            switch self {
            case .processingSystemPrompts, .processingFunctionCalls:
                true
            case .generatingResponse, .completed, .error:
                false
            }
        }
        
        func calculateNewProcessingState(basedOn llmSession: any LLMSession) async -> ProcessingState {
            // Alerts and sheets can not be displayed at the same time.
            if case .error = await llmSession.state {
                return .error
            }
            guard let lastMessage = await llmSession.context.last else {
                return self
            }
            switch lastMessage.role {
            case .system:
                return .processingSystemPrompts
            case .assistant(let toolCalls):
                if !toolCalls.isEmpty {
                    var currentCall: Int
                    let totalCalls: Int
                    if case let .processingFunctionCalls(currentCurrentCall, currentTotalCalls) = self {
                        currentCall = currentCurrentCall
                        totalCalls = currentTotalCalls
                    } else {
                        currentCall = 0
                        totalCalls = 0
                    }
                    
                    currentCall += toolCalls.count
                    return .processingFunctionCalls(
                        currentCall: currentCall,
                        totalCalls: max(currentCall, totalCalls)
                    )
                } else {
                    return .generatingResponse
                }
            case .tool:
                var currentCall: Int
                let totalCalls: Int
                if case let .processingFunctionCalls(currentCurrentCall, currentTotalCalls) = self {
                    currentCall = currentCurrentCall
                    totalCalls = currentTotalCalls
                } else {
                    currentCall = 0
                    totalCalls = 0
                }
                currentCall += 1
                return .processingFunctionCalls(
                    currentCall: currentCall,
                    totalCalls: max(currentCall, totalCalls)
                )
            case .user:
                return self
            }
        }
    }
}
