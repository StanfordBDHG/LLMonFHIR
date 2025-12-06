//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


private struct PulsatingEffect: ViewModifier {
    let isEnabled: Bool
    @State private var scale: CGFloat = 1.0


    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isEnabled) { _, newValue in
                if newValue {
                    startPulsing()
                } else {
                    stopPulsing()
                }
            }
            .onAppear {
                if isEnabled {
                    startPulsing()
                }
            }
    }


    private func startPulsing() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.2
        }
    }

    private func stopPulsing() {
        withAnimation {
            scale = 1.0
        }
    }
}


struct UserStudyChatToolbar: ToolbarContent {
    var viewModel: UserStudyChatViewModel

    let isInputDisabled: Bool
    let onDismiss: () -> Void

    var body: some ToolbarContent {
        dismissButton
        continueButton
        shareButton
    }

    private var dismissButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                viewModel.setDismissDialogPresented(true)
            } label: {
                Image(systemName: "xmark")
                    .accessibilityLabel("Dismiss")
            }
            .confirmationDialog(
                "Going back will reset your chat history.",
                isPresented: Binding<Bool>(
                    get: { viewModel.isDismissDialogPresented },
                    set: { viewModel.setDismissDialogPresented($0) }
                ),
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
            let button = Button {
                viewModel.setSurveyViewPresented(true)
            } label: {
                Label("Next Task", systemImage: "arrow.forward.circle")
                    .accessibilityLabel("Next Task")
                    .modifier(PulsatingEffect(isEnabled: !isInputDisabled))
            }
            .disabled(isInputDisabled)
            if viewModel.navigationState != .completed {
                if #available(iOS 26.0, *) {
                    button
                        .if(!isInputDisabled) { $0.buttonStyle(.glassProminent) }
                        .animation(.interactiveSpring, value: isInputDisabled)
                } else {
                    button
                }
            }
        }
    }
    
    private var shareButton: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if viewModel.navigationState == .completed {
                ShareButton(viewModel: viewModel)
            }
        }
    }
}


extension UserStudyChatToolbar {
    private struct ShareButton: View {
        var viewModel: UserStudyChatViewModel
        @State private var viewState: ViewState = .idle
        @State private var reportUrl: URL?
        
        var body: some View {
            // NOTE that this is intentionally a custom Button with a `shareSheet` modifier, instead of a `ShareLink`,
            // the reason being that, for some reason, sharing via the ShareLink takes like 5 seconds to bring up the sheet
            // (with no indication on the view that it is active), while the custom approach here is way faster,
            // and also somehow gets us a significantly nicer-looking share sheet...
            AsyncButton(state: $viewState) {
                reportUrl = try await viewModel.generateStudyReportFile()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityLabel("Share Survey Results")
            }
            .studyReportShareSheet(url: $reportUrl, for: viewModel.survey)
        }
    }
}


extension View {
    @ViewBuilder
    fileprivate func studyReportShareSheet(
        url urlBinding: Binding<URL?>,
        for survey: Survey
    ) -> some View {
        if EmailSheet.isAvailable, let recipient = survey.reportEmail, !recipient.isEmpty {
            self.sheet(item: urlBinding, id: \.self) { url in
                EmailSheet(message: EmailSheet.Message(
                    recipient: recipient,
                    subject: "LLMonFHIR usabiity study result",
                    body: """
                        The attached file contains your\(survey.encryptionKey != nil ? " encrypyed" : "") results of the usability study.
                        
                        Please send the email to our team at \(recipient).
                        
                        Thank you for helping us improve the LLMonFHIR app!
                        """,
                    attachments: [url]
                )) { _ in
                    urlBinding.wrappedValue = nil
                }
            }
        } else {
            self.shareSheet(item: Binding<ShareSheetInput?> {
                urlBinding.wrappedValue.map { ShareSheetInput($0) }
            } set: { newValue in
                urlBinding.wrappedValue = newValue == nil ? nil : urlBinding.wrappedValue
            })
        }
    }
}
