//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import Foundation
import SwiftUI


struct StudyQRCodeButton: View {
    var body: some View {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            CreateQRCodeButton()
        } else {
            ScanQRCodeButton()
        }
    }
}


private struct ScanQRCodeButton: View {
    @Environment(CurrentStudyManager.self) private var studyManager
    
    @State private var showQRCodeScanner = false
    
    var body: some View {
        Button {
            showQRCodeScanner = true
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .accessibilityLabel("Scan code to enroll in study")
        }
        .qrCodeScanningSheet(isPresented: $showQRCodeScanner) { payload in
            do {
                try studyManager.handleQRCode(payload: payload)
                showQRCodeScanner = false
                return .stopScanning
            } catch {
                print("Failed to start study: \(error)")
                return .continueScanning
            }
        }
    }
}


private struct CreateQRCodeButton: View {
    @State private var isPresented = false
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "qrcode.viewfinder")
                .accessibilityLabel("Scan code to enroll in study")
        }
        .fullScreenCover(isPresented: $isPresented) {
            CreateEnrollmentQRCodeSheet()
        }
    }
}
