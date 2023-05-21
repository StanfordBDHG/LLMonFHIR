//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct HomeView: View {
    enum Tabs: String {
        case fhirResources
    }
    
    
    @AppStorage(StorageKeys.homeTabSelection) var selectedTab = Tabs.fhirResources
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("FHIR Resources")
                .tag(Tabs.fhirResources)
                .tabItem {
                    Label("FHIR_RESOURCES_TAB_TITLE", systemImage: "server.rack")
                }
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
