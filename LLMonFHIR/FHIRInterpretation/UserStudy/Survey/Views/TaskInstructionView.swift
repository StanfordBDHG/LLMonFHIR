//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct TaskInstructionView: View {
    let task: SurveyTask
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let instruction = task.instruction {
                        Text(instruction)
                    }
                }

                Section {
                    Button {
                        isPresented = false
                    } label: {
                        Text("OK")
                            .frame(maxWidth: .infinity)
                            .padding(4)
                    }
                    .padding(.horizontal, -16)
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle("Task \(task.id)")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
