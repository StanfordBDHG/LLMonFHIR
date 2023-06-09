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


struct FHIRResource: Sendable, Identifiable, Hashable {
    enum VersionedFHIRResource: Hashable {
        case r4(ModelsR4.Resource) // swiftlint:disable:this identifier_name
        case dstu2(ModelsDSTU2.Resource)
    }
    
    let versionedResource: VersionedFHIRResource
    let displayName: String
    
    
    var id: String? {
        switch versionedResource {
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
    
    var resourceType: String {
        switch versionedResource {
        case let .r4(resource):
            return ResourceProxy(with: resource).resourceType
        case let .dstu2(resource):
            return ResourceProxy(with: resource).resourceType
        }
    }
    
    var compactJSONDescription: String {
        json(withConfiguration: [.sortedKeys, .withoutEscapingSlashes])
    }
    
    var jsonDescription: String {
        json(withConfiguration: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }
    
    
    private func json(withConfiguration outputFormatting: JSONEncoder.OutputFormatting) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        
        switch versionedResource {
        case let .r4(resource):
            return (try? String(decoding: encoder.encode(resource), as: UTF8.self)) ?? "{}"
        case let .dstu2(resource):
            return (try? String(decoding: encoder.encode(resource), as: UTF8.self)) ?? "{}"
        }
    }
}
