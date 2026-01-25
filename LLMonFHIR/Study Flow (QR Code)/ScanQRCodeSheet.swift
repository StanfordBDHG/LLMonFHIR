//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import AVFoundation
import Foundation
import OSLog
import SpeziViews
import SwiftUI
import VisionKit


enum QRCodeScanningResponse {
    case continueScanning
    case stopScanning
}


private struct ScanQRCodeSheet: View {
    let onSuccess: @Sendable @MainActor (_ payload: String) -> QRCodeScanningResponse
    
    @State private var isDeniedCameraAccess = false
    @State private var isScanning = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isDeniedCameraAccess {
                    permissionsDeniedInfo
                } else {
                    scanner
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton()
                }
            }
        }
        .task {
            isDeniedCameraAccess = switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted:
                true
            default:
                false
            }
        }
    }
    
    private var scanner: some View {
        #if targetEnvironment(simulator)
        ContentUnavailableView(
            "No Study Loaded",
            systemImage: "document.badge.gearshape",
            // swiftlint:disable:next line_length
            description: Text("Launch LLMonFHIR into its study mode by enabling the `--mode study:edu.stanford.LLMonFHIR.usabilityStudy` flag in Xcode (via the `⌘ ⇧ ,` shortcut)")
        )
        #else
        DataScannerView(isScanning: $isScanning, onSuccess: onSuccess)
            .ignoresSafeArea()
            .onAppear {
                isScanning = true
            }
            .onDisappear {
                isScanning = false
            }
        #endif
    }
    
    private var permissionsDeniedInfo: some View {
        ContentUnavailableView {
            Text("Unable to access Camera")
        } description: {
            Text("You must allow LLMonFHIR to access the camera in order to be able to scan a QR code")
        } actions: {
            Button("Allow in Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(url)
            }
        }
    }
}


private struct DataScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = DataScannerViewController
    
    private let logger = Logger(subsystem: "edu.stanford.LLMonFHIR", category: "QRCodeScanning")
    let isScanning: Binding<Bool>
    let onSuccess: @Sendable @MainActor (_ payload: String) -> QRCodeScanningResponse
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ viewController: DataScannerViewController, context: Context) {
        context.coordinator.parent = self
        switch (self.isScanning.wrappedValue, viewController.isScanning) {
        case (true, true), (false, false):
            break
        case (true, false):
            do {
                try viewController.startScanning()
            } catch {
                logger.error("Unable to start scanning: \(error)")
            }
        case (false, true):
            viewController.stopScanning()
        }
    }
}


extension DataScannerView {
    fileprivate final class Coordinator: DataScannerViewControllerDelegate {
        var parent: DataScannerView
        private var shouldProcessResults = true
        
        init(parent: DataScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard shouldProcessResults else {
                return
            }
            for item in addedItems {
                guard case .barcode(let barcode) = item else {
                    continue
                }
                guard barcode.observation.symbology == .qr, let payload = barcode.payloadStringValue else {
                    break
                }
                switch parent.onSuccess(payload) {
                case .stopScanning:
                    shouldProcessResults = false
                    dataScanner.stopScanning()
                    parent.isScanning.wrappedValue = false
                    return
                case .continueScanning:
                    continue
                }
            }
        }
    }
}


extension View {
    /// Presents a sheet with a QR code scanner.
    ///
    /// - Note: The caller is responsible for dismissing the sheet.
    ///
    /// - parameter isPresented: Controls the visibility of the sheet.
    /// - parameter onSuccess: A closure that is called with the first QR the scanner has found.
    func qrCodeScanningSheet(
        isPresented: Binding<Bool>,
        onSuccess: @escaping @Sendable @MainActor (_ payload: String) -> QRCodeScanningResponse
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ScanQRCodeSheet(onSuccess: onSuccess)
        }
    }
}
