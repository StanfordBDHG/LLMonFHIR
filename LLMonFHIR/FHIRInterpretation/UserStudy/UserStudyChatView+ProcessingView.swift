//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import SwiftUI

struct UserStudyChatProcessingView: View {
    let model: UserStudyChatViewModel
    
    var body: some View {
        Group {
            if model.isProcessing {
                Group {
                    if #available(iOS 26.0, *) {
                        content
                            .padding(.top, 6)
                            .glassEffect()
                            .padding(.horizontal)
                    } else {
                        content
                            .background(.ultraThinMaterial)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .animation(.interactiveSpring, value: model.isProcessing)
    }
    
    private var content: some View {
        VStack(spacing: 8) {
            ProgressView(value: model.processingState.progress, total: 100)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .animation(.easeInOut(duration: 0.3), value: model.processingState.progress)
            
            Text(model.processingState.statusDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.3), value: model.processingState.statusDescription)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
