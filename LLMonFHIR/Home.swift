//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    @State private var showMultipleResourcesChat = false
    @AppStorage(StorageKeys.enableTextToSpeech) private var textToSpeech = StorageKeys.Defaults.enableTextToSpeech


    var body: some View {
        NavigationStack {
            ResourceView(showMultipleResourcesChat: $showMultipleResourcesChat)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showMultipleResourcesChat) {
                    MultipleResourcesChatView(
                        navigationTitle: "LLM on FHIR",
                        textToSpeech: $textToSpeech
                    )
                }
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    showSettings.toggle()
                },
                label: {
                    Image(systemName: "gear")
                        .accessibilityLabel(Text("SETTINGS"))
                }
            )
        }
    }
}

#Preview {
    HomeView()
        .previewWith(standard: LLMonFHIRStandard()) {}
}
