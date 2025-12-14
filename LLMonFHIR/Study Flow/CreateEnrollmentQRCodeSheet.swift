//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation
import SwiftUI


struct CreateEnrollmentQRCodeSheet: View {
    private struct CodeGenerationOptions: Equatable {
        var studyId: Study.ID?
        var expires = true
        var validDuration: Duration = .seconds(5)
        var correctionLevel: QRCodeGenerator.CorrectionLevel = .high
    }
    
    @State private var options = CodeGenerationOptions()
    @State private var qrCode: Image?
    @State private var imageRefreshTask: Task<Void, any Error>?
    
    var body: some View {
        NavigationStack {
            HStack {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        leftColumn
                            .frame(width: geometry.size.width * 0.67)
                        Divider()
                        rightColumn
                    }
                }
            }
            .navigationTitle("Create Study Enrollment QR Code")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: options) { _, options in
            updateQRCode()
            imageRefreshTask?.cancel()
            imageRefreshTask = Task {
                guard options.expires else {
                    return
                }
                while true {
                    try? await Task.sleep(for: options.validDuration / 2)
                    guard !Task.isCancelled else {
                        return
                    }
                    updateQRCode()
                }
            }
        }
    }
    
    @ViewBuilder private var leftColumn: some View {
        VStack {
            if let qrCode {
                qrCode
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 600, height: 600)
            } else {
                Text("Select a study on the right.")
            }
        }
    }
    
    @ViewBuilder private var rightColumn: some View {
        Form { // swiftlint:disable:this closure_body_length
            Section {
                Picker("Study", selection: $options.studyId) {
                    Text("–")
                        .tag(Study.ID?.none)
                        .selectionDisabled()
                    Divider()
                    ForEach(AppConfigFile.current().studies) { study in
                        Text(study.title)
                            .tag(study.id)
                    }
                }
            }
            Section {
                Toggle("Expires", isOn: $options.expires)
                if options.expires {
                    Picker("Valid for", selection: $options.validDuration) {
                        let options: [Duration] = [.seconds(5), .seconds(30)]
                        ForEach(options, id: \.self) { option in
                            Text(option, format: Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes, .seconds], width: .narrow))
                                .tag(option)
                        }
                    }
                }
            } footer: {
                Text("STUDY_QR_CODE_GEN_EXPIRATION_FOOTER")
            }
            Section("Other") {
                Picker("Correction Level", selection: $options.correctionLevel) {
                    Text("Low")
                        .tag(QRCodeGenerator.CorrectionLevel.low)
                    Text("Medium")
                        .tag(QRCodeGenerator.CorrectionLevel.medium)
                    Text("High")
                        .tag(QRCodeGenerator.CorrectionLevel.high)
                    Text("Highest")
                        .tag(QRCodeGenerator.CorrectionLevel.highest)
                }
            }
        }
    }
    
    private func updateQRCode() {
        guard let studyId = options.studyId else {
            qrCode = nil
            return
        }
        let payload = StudyQRCodeHandler.QRCodePayload(
            studyId: studyId,
            expires: options.expires ? .now + options.validDuration.timeInterval : nil
        )
        guard let payload = try? payload.qrCodePayload() else {
            qrCode = nil
            return
        }
        qrCode = QRCodeGenerator.qrCode(withPayload: payload, correctionLevel: options.correctionLevel)
    }
}
