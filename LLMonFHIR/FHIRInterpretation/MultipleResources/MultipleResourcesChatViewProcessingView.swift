//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct MultipleResourcesChatViewProcessingView: View {
    let viewModel: MultipleResourcesChatViewModel
    
    var body: some View {
        Group {
            if viewModel.isProcessing {
                Group {
                    if #available(iOS 26.0, *) {
                        content
                            .padding(.top, 6)
                            #if swift(>=6.2)
                            .glassEffect()
                            #endif
                            .padding(.horizontal)
                    } else {
                        content
                            .background(.ultraThinMaterial)
                    }
                }
                .padding(.bottom, 8)
            }
        }
            .animation(.interactiveSpring, value: viewModel.isProcessing)
    }
    
    private var content: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.processingState.progress, total: 100)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .animation(.easeInOut(duration: 0.3), value: viewModel.processingState.progress)
            
            Text(viewModel.processingState.statusDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.processingState.statusDescription)
        }
            .padding(.horizontal)
            .padding(.vertical, 4)
    }
}
