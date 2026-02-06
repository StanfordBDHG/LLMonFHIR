//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


@MainActor
@Observable
final class NPSAnswerState {
    private(set) var answer: Int?

    func update(_ value: Int) {
        answer = value
    }

    func isAnswered(isOptional: Bool) -> Bool {
        if isOptional {
            return true
        }
        return answer != nil
    }
}

/// A view for collecting Net Promoter Score responses
struct NPSView: View {
    /// The valid range for this NPS question
    let range: ClosedRange<Int>

    /// The state object for managing answers
    let answerState: NPSAnswerState


    var body: some View {
        RadioSelectionView(
            range: range,
            selectedValue: answerState.answer,
            displayText: { value in
                switch value {
                case 0: return "\(value) (Would not recommend)"
                case 10: return "\(value) (Would recommend)"
                default: return "\(value)"
                }
            },
            onSelect: { value in
                answerState.update(value)
            }
        )
    }
}
