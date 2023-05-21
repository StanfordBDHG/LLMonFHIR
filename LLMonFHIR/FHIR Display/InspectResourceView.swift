//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


struct InspecResourceView: View {
    var versionedResource: VersionedResource
    
    
    var body: some View {
        List {
            Section("FHIR Resource") {
                LazyText(text: versionedResource.jsonDescription)
                    .fontDesign(.monospaced)
                    .lineLimit(1)
                    .font(.caption2)
            }
        }
    }
}
