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
    typealias BaseType = FHIRResource
    typealias RemovalContext = FHIRRemovalContext
    
    
    struct FHIRRemovalContext: Sendable, Identifiable {
        let id: BaseType.ID
        let resourceType: ResourceType
        
        
        init(id: BaseType.ID, resourceType: ResourceType) {
            self.id = id
            self.resourceType = resourceType
        }
    }
    
    
    private var _resources: [FHIRResource.ID: FHIRResource] = [:] {
        didSet {
            _Concurrency.Task { @MainActor in
                objectWillChange.send()
            }
        }
    }
    
    var resources: [FHIRResource] {
        Array(_resources.values)
    }
    
    
    func registerDataSource(_ asyncSequence: some TypedAsyncSequence<DataChange<BaseType, RemovalContext>>) {
        _Concurrency.Task {
            for try await dateSourceElement in asyncSequence {
                switch dateSourceElement {
                case let .addition(resource):
                    guard let id = resource.id else {
                        continue
                    }
                    _resources[id] = resource
                case let .removal(removalContext):
                    guard let id = removalContext.id else {
                        continue
                    }
                    _resources[id] = nil
                }
            }
        }
    }
}
