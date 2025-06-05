//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


extension UserStudyChatViewModel {
    enum ProcessingState: Equatable {
        case processingSystemPrompts
        case processingFunctionCalls(progress: Double, currentCall: Int, totalCalls: Int)
        case generatingResponse
        case completed

        var progress: Double {
            switch self {
            case .processingSystemPrompts:
                return 0
            case .processingFunctionCalls(let progress, _, _):
                return 20 + progress * 70
            case .generatingResponse:
                return 90
            case .completed:
                return 100
            }
        }

        var statusDescription: String {
            switch self {
            case .processingSystemPrompts:
                return "Processing system prompts..."
            case let .processingFunctionCalls(_, current, total):
                return "Processing data (\(current)/\(total))..."
            case .generatingResponse:
                return "Generating response..."
            case .completed:
                return "Processing completed"
            }
        }
    }
}
