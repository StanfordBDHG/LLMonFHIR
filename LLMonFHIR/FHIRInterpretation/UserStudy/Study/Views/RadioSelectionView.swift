//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// A reusable view component for displaying radio button selection options
struct RadioSelectionView: View {
    /// The range of integer values to display as selectable options
    let range: ClosedRange<Int>

    /// The currently selected value, which can be nil if nothing is selected
    let selectedValue: Int?

    /// A closure that converts an integer value to its display text
    let displayText: (Int) -> String

    /// A closure that's called when a selection is made, passing the selected integer value
    let onSelect: (Int) -> Void

    var body: some View {
        ForEach(range, id: \.self) { value in
            Button(action: { onSelect(value) }) {
                HStack {
                    Text(displayText(value))

                    Spacer()

                    Image(systemName: "circle")
                        .accessibilityHidden(true)
                        .foregroundStyle(selectedValue == value ? .accent : .secondary)
                        .overlay {
                            if selectedValue == value {
                                Image(systemName: "circle.fill")
                                    .accessibilityHidden(true)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.accent)
                            }
                        }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
