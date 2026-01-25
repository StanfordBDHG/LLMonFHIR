//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct IRBApprovalBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("Approved by Stanford IRB")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}
