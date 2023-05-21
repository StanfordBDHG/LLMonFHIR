//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
@preconcurrency import ModelsR4
import Spezi
import XCTRuntimeAssertions


actor FHIR: Standard, ObservableObject, ObservableObjectProvider {
    typealias BaseType = VersionedResource
    typealias RemovalContext = FHIRRemovalContext
    
    
    struct FHIRRemovalContext: Sendable, Identifiable {
        let id: BaseType.ID
        let resourceType: ResourceType
        
        
        init(id: BaseType.ID, resourceType: ResourceType) {
            self.id = id
            self.resourceType = resourceType
        }
    }
    
    
    var resources: [VersionedResource.ID: VersionedResource] = [:] {
        didSet {
            _Concurrency.Task { @MainActor in
                objectWillChange.send()
            }
        }
    }
    
    
    func registerDataSource(_ asyncSequence: some TypedAsyncSequence<DataChange<BaseType, RemovalContext>>) {
        _Concurrency.Task {
            for try await dateSourceElement in asyncSequence {
                switch dateSourceElement {
                case let .addition(resource):
                    guard let id = resource.id else {
                        continue
                    }
                    resources[id] = resource
                case let .removal(removalContext):
                    guard let id = removalContext.id else {
                        continue
                    }
                    resources[id] = nil
                }
            }
        }
    }
}
