//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// periphery:ignore:all - API

public import Foundation
public import SpeziFHIR
private import SpeziFoundation


/// Sendable mechanism for `FHIRResource`s with limited access needed for LLMonFHIR.
public struct SendableFHIRResource: @unchecked Sendable {
    private let _resource: FHIRResource
    private let readWriteLock = RWLock()
    
    
    public var id: FHIRResource.ID {
        readWriteLock.withReadLock {
            _resource.id
        }
    }
    
    public var functionCallIdentifier: String {
        readWriteLock.withReadLock {
            _resource.functionCallIdentifier
        }
    }
    
    public var date: Date? {
        readWriteLock.withReadLock {
            _resource.date
        }
    }
    
    public var jsonDescription: String {
        readWriteLock.withReadLock {
            _resource.jsonDescription
        }
    }
    
    
    public init(resource: FHIRResource) {
        _resource = resource
    }
    
    
    public func stringifyAttachments() throws {
        try readWriteLock.withWriteLock {
            try _resource.stringifyAttachments()
        }
    }
}


extension SendableFHIRResource: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._resource == rhs._resource
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_resource)
    }
}
