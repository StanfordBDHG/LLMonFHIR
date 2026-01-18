//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


/// A sheet that is presented at the bottom of the screen and sizes its height based on its content.
struct BottomSheet<Content: View>: View {
    private let content: Content
    @State private var height: CGFloat = .zero
    
    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .onHeightChange {
                        height = $0 + 100
                    }
            }
        }
        .presentationDetents(height == .zero ? [.medium] : [.height(height)])
    }
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}


extension View {
    fileprivate func onHeightChange(_ action: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        action(geometry.size.height)
                    }
                    .onChange(of: geometry.size.height) { _, newHeight in
                        action(newHeight)
                    }
            }
        }
    }
}
