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


struct ResourceView: View {
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRStore.self) private var fhirStore
    @Environment(HealthKit.self) private var healthKit
    @Binding var showMultipleResourcesChat: Bool
    @WaitingState private var waitingState
    
    var body: some View {
        FHIRResourcesView("Your Health Records") {
            FHIRResourcesInstructionsView()
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
    
    private var chatWithAllResourcesButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                _chatWithAllResourcesButton
                    .buttonStyle(.glassProminent)
            } else {
                _chatWithAllResourcesButton
                    .buttonStyle(.borderedProminent)
                    .padding(-8)
            }
        }
    }
    
    private var _chatWithAllResourcesButton: some View {
        MainActionButton {
            showMultipleResourcesChat = true
        }
    }
}


extension ResourceView {
    private struct MainActionButton: View {
        private enum Config {
            case chatWithResources
            case authorizeHealthKit
        }
        
        @Environment(\.colorScheme) private var colorScheme
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
        
        private var foregroundColor: Color {
            waitingState.isWaiting ? .black : .white
        }
    }
}


extension ViewState {
    var isError: Bool {
        switch self {
        case .error:
            true
        case .idle, .processing:
            false
        }
    }
}
