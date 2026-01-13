//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// periphery:ignore:all - API

import Foundation
@preconcurrency import ModelsR4
import SpeziFHIR
import SpeziFoundation


/// Sendable mechanism for `FHIRResource`s with limited access needed for LLMonFHIR.
struct SendableFHIRResource: @unchecked Sendable {
    private let _resource: FHIRResource
    private let readWriteLock = RWLock()
    
    
    var id: FHIRResource.ID {
        readWriteLock.withReadLock {
            _resource.id
        }
    }
    
    var functionCallIdentifier: String {
        readWriteLock.withReadLock {
            _resource.functionCallIdentifier
        }
    }
    
    var date: Date? {
        readWriteLock.withReadLock {
            _resource.date
        }
    }
    
    var jsonDescription: String {
        readWriteLock.withReadLock {
            _resource.jsonDescription
        }
    }
    
    
    init(resource: FHIRResource) {
        _resource = resource
    }
    
    
    func stringifyAttachments() throws {
        try readWriteLock.withWriteLock {
            try _resource.stringifyAttachments()
        }
    }
}


extension SendableFHIRResource: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._resource == rhs._resource
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(_resource)
    }
}
