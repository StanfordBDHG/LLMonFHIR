//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SpeziViews
import SwiftUI


struct UserStudyChatToolbar: ToolbarContent {
    @Environment(FirebaseUpload.self) private var uploader: FirebaseUpload?
    
    var model: UserStudyChatViewModel
    @Binding var isTextToSpeechEnabled: Bool
    let onDismiss: @MainActor () -> Void
    
    private var enableContinueAction: Bool {
        model.shouldEnableContinueToNextTaskAction
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            dismissButton
        }
        ToolbarItemGroup(placement: .primaryAction) {
            if model.study.isUnguided {
                resetChatButton
                textToSpeechButton
            } else {
                viewInstructionsButton
            }
        }
        ToolbarItem(placement: .primaryAction) {
            if model.study.isUnguided {
                // if the study is unguided, we always enable sharing
                shareButton
            } else {
                // otherwise, we conditionally have either the continue button, or the share button
                if model.navigationState == .completed {
                    shareButton
                } else {
                    continueButton
                }
            }
        }
    }

    @ViewBuilder private var dismissButton: some View {
        @Bindable var model = model
        Button {
            model.isDismissDialogPresented = true
        } label: {
            Image(systemName: "xmark")
                .accessibilityLabel("Dismiss")
        }
        .confirmationDialog(
            "Going back will reset your chat history.",
            isPresented: $model.isDismissDialogPresented,
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
    
    private var resetChatButton: some View {
        Button {
            model.startNewConversation()
        } label: {
            Label("Reset Chat", systemImage: "trash")
        }
        .disabled(model.isProcessing)
    }
    
    private var textToSpeechButton: some View {
        Button {
            isTextToSpeechEnabled.toggle()
        } label: {
            Image(systemName: isTextToSpeechEnabled ? "speaker" : "speaker.slash")
                .accessibilityLabel("\(isTextToSpeechEnabled ? "Disable" : "Enable") Text to Speech")
        }
        .disabled(model.isProcessing)
    }
    
    private var viewInstructionsButton: some View {
        Button {
            model.presentedSheet = .instructions
        } label: {
            Image(systemName: "info.circle")
                .accessibilityLabel("View Instructions")
        }
        .disabled(model.isTaskIntructionButtonDisabled)
    }
    
    @ViewBuilder private var continueButton: some View {
        let button = Button {
            model.advance()
        } label: {
            Label("Next Task", systemImage: "arrow.forward.circle")
                .accessibilityLabel("Next Task")
                .pulsate(enableContinueAction)
        }
        .disabled(!enableContinueAction)
        if model.navigationState != .completed {
            if #available(iOS 26.0, *) {
                button
                    .if(enableContinueAction) { $0.buttonStyle(.glassProminent) }
                    .animation(.interactiveSpring, value: !enableContinueAction)
            } else {
                button
            }
        }
    }
    
    @ViewBuilder private var shareButton: some View {
        // we only show the share button if no firebase upload is taking place.
        if uploader == nil || model.study.isUnguided {
            ShareButton(model: model)
                .disabled(model.isProcessing)
        }
    }
}


extension UserStudyChatToolbar {
    private struct ShareButton: View {
        var model: UserStudyChatViewModel
        @State private var viewState: ViewState = .idle
        @State private var reportUrl: URL?
        
        var body: some View {
            // NOTE that this is intentionally a custom Button with a `shareSheet` modifier, instead of a `ShareLink`,
            // the reason being that, for some reason, sharing via the ShareLink takes like 5 seconds to bring up the sheet
            // (with no indication on the view that it is active), while the custom approach here is way faster,
            // and also somehow gets us a significantly nicer-looking share sheet...
            AsyncButton(state: $viewState) {
                reportUrl = try await model.generateStudyReportFile(encryptIfPossible: true)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .accessibilityLabel("Share Survey Results")
            }
            .studyReportShareSheet(url: $reportUrl, for: model.inProgressStudy.config)
        }
    }
}


extension View {
    @ViewBuilder
    fileprivate func studyReportShareSheet(
        url urlBinding: Binding<URL?>,
        for studyConfig: StudyConfig
    ) -> some View {
        if EmailSheet.isAvailable, !studyConfig.reportEmail.isEmpty {
            self.sheet(item: urlBinding, id: \.self) { url in
                EmailSheet(message: EmailSheet.Message(
                    recipient: studyConfig.reportEmail,
                    subject: "LLMonFHIR usabiity study result",
                    body: """
                        The attached file contains your\(studyConfig.encryptionKey != nil ? " encrypyed" : "") results of the usability study.
                        
                        Please send the email to our team at \(studyConfig.reportEmail).
                        
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
