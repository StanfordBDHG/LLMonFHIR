//
// This source file is part of the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIRMockDataStorageProvider
import SwiftUI


struct MockUpload: View {
    var body: some View {
        NavigationStack {
            MockUploadList()
        }
    }
}


#if DEBUG
struct MockUpload_Previews: PreviewProvider {
    static var previews: some View {
        MockUpload()
            .environmentObject(MockDataStorageProvider())
    }
}
#endif
