//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

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


extension View {
    func pulsate(_ isEnabled: Bool) -> some View {
        self.modifier(PulsatingEffect(isEnabled: isEnabled))
    }
}
