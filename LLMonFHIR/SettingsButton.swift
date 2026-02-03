//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziAccessGuard
import SwiftUI


struct SettingsButton: View {
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @State private var isPresentingSheet = false
    
    var body: some View {
        Button {
            isPresentingSheet = true
        } label: {
            Image(systemName: "gearshape")
                .accessibilityLabel(Text("SETTINGS"))
        }
        .sheet(isPresented: $isPresentingSheet) {
            if fhirInterpretationModule.currentStudy?.config != nil {
                AccessGuarded(.userStudySettings) {
                    SettingsView()
                }
            } else {
                SettingsView()
            }
        }
    }
}

extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    /// A unique identifier for user study access control.
    /// Used to protect and manage access to user study related features and views.
    static let userStudySettings: Self = .passcode("UserStudySettingsGuard")
}
