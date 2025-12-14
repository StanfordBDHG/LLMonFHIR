//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct HomeView: View {
    @Environment(FHIRMultipleResourceInterpreter.self) var interpreter
    @State private var showMultipleResourcesChat = false
    @State private var study: Study?

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
            .fullScreenCover(item: $study) { study in
                StudyHomeView(study: study)
            }
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            StudyQRCodeButton { study in
                guard self.study == nil else {
                    return
                }
                self.study = study
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            SettingsButton(hideBehindAccessGuard: false)
        }
    }
}

#Preview {
    HomeView()
        .previewWith(standard: LLMonFHIRStandard()) {}
}
