//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziFHIRMockPatients
import SpeziHealthKit
import SpeziViews
import SwiftUI


struct ResourceView: View { // Maybe rename this at some point?
    @Environment(FHIRStore.self) private var fhirStore
    @Binding var showMultipleResourcesChat: Bool
    
    var body: some View {
        FHIRResourcesView("Your Health Records") {
            Section {
                FHIRResourcesInstructionsView()
            } footer: {
                #if targetEnvironment(simulator)
                if LLMonFHIR.mode == .standalone {
                    Text(verbatim: "Launch into study mode by enabling the `--mode study:ID` flag in Xcode (via the `⌘ ⇧ ,` shortcut)")
                }
                #endif
            }
        } action: {
            chatWithAllResourcesButton
                .padding(-18)
        }
        .task {
            if LLMonFHIR.mode == .test {
                await fhirStore.loadTestingResources()
            }
        }
    }
    
    @ViewBuilder private var chatWithAllResourcesButton: some View {
        let button = MainActionButton {
            showMultipleResourcesChat = true
        }
        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
        } else {
            button
                .buttonStyle(.borderedProminent)
                .padding(-8)
        }
    }
}


extension ResourceView {
    private struct MainActionButton: View {
        private enum Config {
            case chatWithResources
            case authorizeHealthKit
        }
        
        @Environment(LLMonFHIRStandard.self) private var standard
        @Environment(HealthKit.self) private var healthKit
        @WaitingState private var waitingState
        
        let chatWithResourcesAction: @MainActor () -> Void
        @State private var viewState: ViewState = .idle // only used for the alert, not for the processing state
        
        private var config: Config {
            if LLMonFHIR.mode == .test || healthKit.isFullyAuthorized {
                .chatWithResources
            } else {
                .authorizeHealthKit
            }
        }
        
        var body: some View {
            PrimaryActionButton(text) {
                switch config {
                case .chatWithResources:
                    chatWithResourcesAction()
                case .authorizeHealthKit:
                    Task {
                        do {
                            try await waitingState.run {
                                try await healthKit.askForAuthorization()
                                await standard.fetchRecordsFromHealthKit()
                            }
                        } catch {
                            viewState = .error(AnyLocalizedError(error: error))
                        }
                    }
                }
            }
            .viewStateAlert(state: $viewState)
        }
        
        private var text: LocalizedStringResource {
            switch (config, waitingState.isWaiting) {
            case (.chatWithResources, false):
                "Chat with all Resources"
            case (.chatWithResources, true):
                "Loading Resources"
            case (.authorizeHealthKit, _):
                "Authorize Health Access"
            }
        }
    }
}
