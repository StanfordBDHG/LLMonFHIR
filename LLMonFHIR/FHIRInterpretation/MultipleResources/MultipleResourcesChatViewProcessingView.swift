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
        if viewModel.isProcessing {
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
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .padding(.bottom, 8)
        }
    }
}
