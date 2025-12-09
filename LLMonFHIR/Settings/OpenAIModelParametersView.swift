//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct OpenAIModelParametersView: View {
    @LocalPreference(.openAIModelTemperature) private var temperature
    @Environment(FHIRInterpretationModule.self) var fhirInterpretationModule


    var body: some View {
        Form {
            temperatureSection
        }
            .navigationTitle("SETTINGS_OPENAI_MODEL_PARAMETERS")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                footerText
            }
    }


    private var temperatureSection: some View {
        Section(
            header: Text("Temperature"),
            footer: Text("Higher values (0.8+) increase randomness and creativity. Lower values (0.2-) make responses more focused and deterministic.")  // swiftlint:disable:this line_length
        ) {
            VStack(spacing: 16) {
                temperatureHeader

                Slider(value: $temperature, in: 0...2, step: 0.05)
                    .tint(temperatureColor)
                    .onChange(of: temperature) {
                        Task {
                            await fhirInterpretationModule.updateSchemas()
                        }
                    }

                temperatureLabels
            }
                .padding(.vertical, 8)
        }
    }

    private var temperatureHeader: some View {
        HStack {
            Text("\(temperature, specifier: "%.2f")")
                .font(.system(.title3))
                .fontWeight(.medium)

            Spacer()

            Text(temperatureDescription)
                .font(.subheadline)
                .foregroundStyle(temperatureColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(temperatureColor.opacity(0.1))
                .cornerRadius(6)
        }
    }

    private var temperatureLabels: some View {
        HStack {
            Text("Focused")
            Spacer()
            Text("Balanced")
            Spacer()
            Text("Creative")
            Spacer()
            Text("Random")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private var footerText: some View {
        Text("Please quit and reopen the app for the changes to take effect.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    }


    private var temperatureDescription: String {
        switch temperature {
        case 0..<0.3:
            return "Focused"
        case 0.3..<0.7:
            return "Balanced"
        case 0.7..<1.3:
            return "Creative"
        case 1.3...:
            return "Random"
        default:
            return ""
        }
    }

    private var temperatureColor: Color {
        switch temperature {
        case 0..<0.3:
            return .blue
        case 0.3..<0.7:
            return .green
        case 0.7..<1.3:
            return .orange
        case 1.3...:
            return .red
        default:
            return .gray
        }
    }
}
