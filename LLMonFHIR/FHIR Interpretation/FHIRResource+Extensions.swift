//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFHIR


extension FHIRResource {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()
    
    var functionCallIdentifier: String {
        resourceType.filter { !$0.isWhitespace }
            + displayName.filter { !$0.isWhitespace }
            + (date.map { FHIRResource.dateFormatter.string(from: $0) } ?? "")
    }
}
