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


struct CreateEnrollmentQRCodeButton: View {
    @State private var isPresented = false
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .accessibilityLabel("Scan code to enroll in study")
        }
        .fullScreenCover(isPresented: $isPresented) {
            CreateEnrollmentQRCodeView()
        }
    }
}


private struct CreateEnrollmentQRCodeView: View {
    @State private var studyId: Survey.ID?
    @State private var enableExpirationTimestamp = true
    @State private var expirationDate = Calendar.current.startOfNextDay(for: .now) - 30
    @State private var correctionLevel: QRCodeGenerator.CorrectionLevel = .high
    
    @State private var qrCode: Image?
    
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
        .onChange(of: studyId) { updateQRCode() }
        .onChange(of: enableExpirationTimestamp) { updateQRCode() }
        .onChange(of: expirationDate) { updateQRCode() }
        .onChange(of: correctionLevel) { updateQRCode() }
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
                Text("No Image")
            }
        }
    }
    
    @ViewBuilder private var rightColumn: some View {
        Form {
            Section {
                Picker("Study", selection: $studyId) {
                    Text("–")
                        .tag(Survey.ID?.none)
                        .selectionDisabled()
                    Divider()
                    ForEach(Survey.allKnownStudies()) { study in
                        Text(study.title)
                            .tag(study.id)
                    }
                }
            }
            Section {
                Toggle("Expires", isOn: $enableExpirationTimestamp)
                if enableExpirationTimestamp {
                    DatePicker("Expiration Date", selection: $expirationDate)
                }
            }
            Section("Other") {
                Picker("Correction Level", selection: $correctionLevel) {
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
        guard let studyId else {
            qrCode = nil
            return
        }
        let payload = CurrentStudyManager.QRCodePayload(
            studyId: studyId,
//            expires: enableExpirationTimestamp ? .now + validity.timeInterval : nil
            expires: enableExpirationTimestamp ? expirationDate : nil
        )
        guard let payload = try? payload.qrCodePayload() else {
            qrCode = nil
            return
        }
        qrCode = QRCodeGenerator.qrCode(withPayload: payload, correctionLevel: correctionLevel)
    }
}
