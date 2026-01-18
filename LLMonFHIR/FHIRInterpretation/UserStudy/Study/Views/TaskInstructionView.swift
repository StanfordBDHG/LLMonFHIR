//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct TaskInstructionView: View {
    let task: SurveyTask
    let userDisplayableCurrentTaskIdx: Int
    /// Called when the sheet should be dismissed
    let onDismiss: @MainActor () -> Void

    var body: some View {
        BottomSheet {
            Group {
                if let instructions = task.instructions {
                    Text(instructions)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("Task \(userDisplayableCurrentTaskIdx)")
            .transforming {
                if #available(iOS 26, *), let title = task.title {
                    $0.navigationSubtitle(title)
                } else {
                    $0
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem {
            if #available(iOS 26, *) {
                Button(role: .close) {
                    onDismiss()
                }
            } else {
                Button {
                    onDismiss()
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                        .accessibilityLabel("Dismiss")
                }
            }
        }
    }
}
