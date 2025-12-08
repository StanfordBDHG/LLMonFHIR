//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SwiftUI


struct ScanStudyQRCodeButton: View {
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
