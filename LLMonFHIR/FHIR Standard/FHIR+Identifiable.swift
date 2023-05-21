//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ModelsR4


extension Resource: Identifiable {
    public typealias ID = FHIRPrimitive<FHIRString>?
}

extension FHIRPrimitive: Identifiable where PrimitiveType: Identifiable { }

extension Optional: Identifiable where Wrapped == FHIRPrimitive<FHIRString> {
    public var id: FHIRPrimitive<FHIRString>? {
        switch self {
        case let .some(value):
            return value
        case .none:
            return nil
        }
    }
}
