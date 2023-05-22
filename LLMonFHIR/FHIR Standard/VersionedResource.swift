//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
@preconcurrency import ModelsDSTU2
@preconcurrency import ModelsR4


enum VersionedResource: Sendable, Identifiable, Hashable {
    case r4(ModelsR4.Resource) // swiftlint:disable:this identifier_name
    case dstu2(ModelsDSTU2.Resource)
    
    
    var id: String? {
        switch self {
        case let .r4(resource):
            guard let id = resource.id?.value?.string else {
                return nil
            }
            return id
        case let .dstu2(resource):
            guard let id = resource.id?.value?.string else {
                return nil
            }
            return id
        }
    }
    
    var compactDescription: String {
        id ?? "No Description Available"
    }
    
    var resourceType: String {
        switch self {
        case let .r4(resource):
            return ResourceProxy(with: resource).resourceType
        case let .dstu2(resource):
            return ResourceProxy(with: resource).resourceType
        }
    }
    
    var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        
        switch self {
        case let .r4(resource):
            return (try? String(decoding: encoder.encode(resource), as: UTF8.self)) ?? "{}"
        case let .dstu2(resource):
            return (try? String(decoding: encoder.encode(resource), as: UTF8.self)) ?? "{}"
        }
    }
}
