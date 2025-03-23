//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct UserStudyChatToolbar: ToolbarContent {
    @ObservedObject var viewModel: UserStudyChatViewModel
    let isInputDisabled: Bool
    let onDismiss: () -> Void


    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            dismissButton
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.navigationState != .completed {
                navigationButton
            }
        }
    }


    private var dismissButton: some View {
        Button(action: { viewModel.isDismissDialogPresented = true }) {
            Image(systemName: "xmark")
                .accessibilityLabel("Dismiss")
        }
        .confirmationDialog(
            "Going back will reset your chat history.",
            isPresented: $viewModel.isDismissDialogPresented,
            titleVisibility: .visible,
            actions: {
                Button("Yes", role: .destructive, action: onDismiss)
                Button("No", role: .cancel) {}
            },
            message: {
                Text("Do you want to continue?")
            }
        )
    }

    private var navigationButton: some View {
        Button {
            viewModel.isSurveyViewPresented = true
        } label: {
            Image(systemName: "arrow.forward.circle")
                .accessibilityLabel("Next Task")
        }
        .disabled(isInputDisabled)
    }
}
