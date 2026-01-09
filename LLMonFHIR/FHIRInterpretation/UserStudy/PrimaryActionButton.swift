//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


struct PrimaryActionButton<Label: View>: View {
    @WaitingState private var waitingState
    
    private let label: @MainActor () -> Label
    private let action: @MainActor () async throws -> Void
    
    var body: some View {
        Button {
            Task { @MainActor in
                do {
                    try await waitingState.run { @MainActor in
                        try await action()
                    }
                } catch {
                    // ???
                }
            }
        } label: {
            HStack(spacing: 8) {
                label()
                    .foregroundStyle(foregroundColor)
                if waitingState.isWaiting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .controlSize(.regular)
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
        .controlSize(.extraLarge)
        .buttonBorderShape(.capsule)
        .disabled(waitingState.isWaiting /*|| viewState.isError*/)
        .animation(.default, value: waitingState.isWaiting /*|| viewState.isError*/)
    }
    
    private var foregroundColor: Color {
        waitingState.isWaiting ? .black : .white
    }
    
    init(
        _ action: @escaping @MainActor () async throws -> Void,
        @ViewBuilder label: @escaping @MainActor () -> Label
    ) {
        self.label = label
        self.action = action
    }
    
    init(
        _ title: LocalizedStringResource,
        action: @escaping @MainActor () async throws -> Void
    ) where Label == Text {
        self.init(action) {
            Text(title)
        }
    }
    
    init(
        _ title: LocalizedStringResource,
        systemImage: String,
        action: @escaping @MainActor () async throws -> Void
    ) where Label == SwiftUI.Label<Text, Image> {
        self.init(action) {
            SwiftUI.Label(title, systemImage: systemImage)
        }
    }
}
