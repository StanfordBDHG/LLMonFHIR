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
    @AppStorage(StorageKeys.onboardingInstructions) private var onboardingInstructions = true
    
    
    var body: some View {
        NavigationStack {
            FHIRResourcesView()
                .toolbar {
                    settingsToolbarItem
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
    }
    
    
    @ToolbarContentBuilder private var settingsToolbarItem: some ToolbarContent {
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


#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
#endif
