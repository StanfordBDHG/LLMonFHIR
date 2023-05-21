//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ModelsR4


extension Optional: CustomStringConvertible, LosslessStringConvertible where Wrapped == FHIRPrimitive<FHIRString> {
    public var description: String {
        switch self {
        case .none:
            return ""
        case let .some(wrapped):
            return wrapped.value?.string ?? ""
        }
    }
    
    
    public init?(_ description: String) {
        self = .some(FHIRPrimitive<FHIRString>(stringLiteral: description))
    }
}
