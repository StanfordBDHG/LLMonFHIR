//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


struct SettingsButton: View {
    @State private var isPresentingSheet = false
    
    var body: some View {
        Button {
            isPresentingSheet = true
        } label: {
            Image(systemName: "gearshape")
                .accessibilityLabel(Text("SETTINGS"))
        }
        .sheet(isPresented: $isPresentingSheet) {
            SettingsView()
        }
    }
}
