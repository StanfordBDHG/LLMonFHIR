//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


struct EarliestHealthRecordsView: View {
    @Environment(\.dismiss) private var dismiss

    let dataSource: [String: Date]
    let dateFormatter: DateFormatter


    var body: some View {
        NavigationView {
            List {
                Section(footer: Text("\n\(Text("HEALTH_RECORDS_SINCE_DISCLAIMER"))")) {
                    ForEach(dataSource.keys.sorted(), id: \.self) { resourceType in
                        if let date = dataSource[resourceType] {
                            HStack {
                                Text(resourceType)
                                    .font(.headline)

                                Spacer()

                                Text(dateFormatter.string(from: date))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("HEALTH_RECORDS_SINCE")
            .navigationBarItems(trailing: dismissButton)
        }
    }


    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Label("Dismiss", systemImage: "xmark")
                .accessibilityLabel("Dismiss")
        }
    }
}
