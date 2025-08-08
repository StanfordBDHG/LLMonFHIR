//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


// AnyHashable is Sendable in Swift 6.2, unchecked can be removed at that point.
/// Errors that can occur when using a LimitedCollectionDictionary
enum LimitedCollectionDictionaryError: @unchecked Sendable, Error {
    case keyNotConfigured(key: AnyHashable)
    case capacityExceeded(key: AnyHashable, maximum: Int)
}

// periphery:ignore - These are fundamental APIs for collection handling, even if not all are used in every context.

/// A dictionary where each key maps to a collection with a maximum capacity.
///
/// This allows setting different capacity limits for different keys.
/// When the limit is reached for a key, adding more elements will throw an error.
struct LimitedCollectionDictionary<Key: Hashable, Element> {
    private(set) var capacityRanges: [Key: ClosedRange<Int>] = [:]
    private(set) var collections: [Key: LimitedCollection<Element>] = [:]

    /// Sets the minimum and maximum number of elements allowed for a key
    /// - Parameters:
    ///   - minimum: Minimum number of elements required
    ///   - maximum: Maximum number of elements allowed
    ///   - key: The key to configure
    /// - Throws: Error if the collection cannot be updated
    mutating func setCapacityRange(minimum: Int, maximum: Int, forKey key: Key) throws {
        precondition(minimum >= 0, "Minimum capacity cannot be negative")
        precondition(maximum >= minimum, "Maximum capacity must be >= minimum")

        capacityRanges[key] = minimum...maximum

        if let existingCollection = collections[key] {
            var newCollection = LimitedCollection<Element>(capacity: maximum)
            try newCollection.append(contentsOf: existingCollection.all)
            collections[key] = newCollection
        }
    }

    /// Removes capacity restrictions for a key
    /// - Parameter key: The key to make unlimited
    mutating func setUnlimitedCapacity(forKey key: Key) {
        capacityRanges.removeValue(forKey: key)
        collections.removeValue(forKey: key)
    }

    /// Adds a single element to a key's collection if within capacity
    /// - Parameters:
    ///   - element: Element to add
    ///   - key: Target key
    /// - Throws: Error if capacity is exceeded or collection cannot be accessed
    mutating func append(_ element: Element, forKey key: Key) throws {
        if collections[key] == nil, let limit = capacityRanges[key]?.upperBound {
            collections[key] = LimitedCollection<Element>(capacity: limit)
        }

        guard var collection = collections[key] else {
            throw LimitedCollectionDictionaryError.keyNotConfigured(key: key)
        }

        do {
            try collection.append(element)
            collections[key] = collection
        } catch LimitedCollectionError.capacityExceeded(let maximum) {
            throw LimitedCollectionDictionaryError.capacityExceeded(key: key, maximum: maximum)
        }
    }

    /// Removes all elements for a key
    /// - Parameter key: The key to clear
    mutating func clearElements(forKey key: Key) {
        collections.removeValue(forKey: key)
    }

    /// Check if the minimum requirement is met for a key
    /// - Parameter key: The key to check
    /// - Returns: True if the minimum is met or no minimum is set
    func isMinReached(forKey key: Key) -> Bool {
        guard let range = capacityRanges[key] else {
            return true
        }

        if range.lowerBound == 0 {
            return true
        }

        guard let collection = collections[key] else {
            return false
        }

        return collection.count >= range.lowerBound
    }

    /// Check if the maximum requirement is met for a key
    /// - Parameter key: The key to check
    /// - Returns: True if the maximum is met or no minimum is set
    func isMaxReached(forKey key: Key) -> Bool {
        guard let range = capacityRanges[key] else {
            return true
        }

        guard let collection = collections[key] else {
            return false
        }

        return collection.count >= range.upperBound
    }

    /// Checks if a capacity range has been configured for a specific key
    /// - Parameter key: The key to check
    /// - Returns: True if a capacity range exists for the key
    func hasConfiguredCapacity(forKey key: Key) -> Bool {
        capacityRanges[key] != nil
    }
}
