//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SwiftUI


struct HomeView: View {
    @Environment(FHIRMultipleResourceInterpreter.self) var interpreter
    @State private var showMultipleResourcesChat = false
    @State private var qrCodeScanResult: StudyQRCodeHandler.ScanResult?

    var body: some View {
        NavigationStack {
            ResourceView(
                showMultipleResourcesChat: $showMultipleResourcesChat
            )
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showMultipleResourcesChat) {
                MultipleResourcesChatView(
                    interpreter: interpreter,
                    navigationTitle: "LLM on FHIR"
                )
            }
            .fullScreenCover(item: $qrCodeScanResult, id: \.self) { scanResult in
                StudyHomeView(
                    study: scanResult.study,
                    config: scanResult.studyConfig,
                    userInfo: scanResult.userInfo
                )
            }
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ScanQRCodeButton { study in
                guard self.qrCodeScanResult == nil else {
                    return
                }
                self.qrCodeScanResult = study
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            SettingsButton()
        }
    }
}

#Preview {
    HomeView()
        .previewWith(standard: LLMonFHIRStandard()) {}
}
