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
    let didScan: @MainActor (Study) -> Void
    
    var body: some View {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            CreateQRCodeButton()
        } else {
            ScanQRCodeButton(didScan: didScan)
        }
    }
}


private struct ScanQRCodeButton: View {
    let didScan: @MainActor (Study) -> Void
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
                didScan(try StudyQRCodeHandler.processQRCode(payload: payload))
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
