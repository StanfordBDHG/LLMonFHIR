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
                Section(footer: Text("\n\(Text("Records Since Disclaimer"))")) {
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
            .navigationTitle("Records since")
            .navigationBarItems(trailing: doneButton)
        }
    }


    private var doneButton: some View {
        Button("Done") {
            dismiss()
        }
    }
}
