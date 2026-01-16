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
    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        NavigationStack {
            ScrollView {
                if let instructions = task.instructions {
                    Text(instructions)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding()
                        .onHeightChange {
                            sheetHeight = $0 + 100
                        }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
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
        .presentationDetents(sheetHeight == .zero ? [.medium] : [.height(sheetHeight)])
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

extension View {
    func onHeightChange(completion: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        completion(geometry.size.height)
                    }
                    .onChange(of: geometry.size.height) { _, newHeight in
                        completion(newHeight)
                    }
            }
        )
    }
    
    @ViewBuilder
    func transforming(@ViewBuilder _ transform: (Self) -> some View) -> some View {
        transform(self)
    }
}
