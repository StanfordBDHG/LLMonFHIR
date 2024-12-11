//
// This source file is part of the Stanford Spezi project
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
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter
    }()
    
    
    var functionCallIdentifier: String {
        resourceType.filter { !$0.isWhitespace }
            + displayName.filter { !$0.isWhitespace }
            + "-"
            + (date.map { FHIRResource.dateFormatter.string(from: $0) } ?? "")
    }
}
