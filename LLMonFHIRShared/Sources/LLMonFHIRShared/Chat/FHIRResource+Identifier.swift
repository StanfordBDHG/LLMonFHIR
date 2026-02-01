//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
public import SpeziFHIR


extension FHIRResource {
    static let functionCallIdentifierDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter
    }()
    
    
    // swiftlint:disable:next missing_docs
    public var functionCallIdentifier: String {
        resourceType.filter { $0.isLetter || $0.isWholeNumber }
            + "-"
            + displayName.filter { $0.isLetter || $0.isWholeNumber }.prefix(75)
            + "-"
            + (date.map { FHIRResource.functionCallIdentifierDateFormatter.string(from: $0) } ?? "")
    }
}
