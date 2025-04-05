//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct UserStudyChatToolbar: ToolbarContent {
    @State private(set) var viewModel: UserStudyChatViewModel

    let isInputDisabled: Bool
    let onDismiss: () -> Void


    var body: some ToolbarContent {
        dismissButton
        continueButton
        shareButton
    }


    private var dismissButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
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
    }

    private var continueButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if viewModel.navigationState != .completed {
                Button {
                    viewModel.isSurveyViewPresented = true
                } label: {
                    Image(systemName: "arrow.forward.circle")
                        .accessibilityLabel("Next Task")
                }
                .disabled(isInputDisabled)
            }
        }
    }

    private var shareButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.navigationState == .completed, let studyReportFile = viewModel.generateStudyReportFile() {
                Button {
                    viewModel.isSharingSheetPresented = true
                } label: {
                    ShareLink(item: studyReportFile) {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("Share Survey Results")
                    }
                }
            }
        }
    }
}
