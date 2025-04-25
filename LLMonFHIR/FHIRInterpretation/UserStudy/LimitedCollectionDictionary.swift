//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//


/// Errors that can occur when using a LimitedCollectionDictionary
enum LimitedCollectionDictionaryError: Error {
    case keyNotConfigured(key: AnyHashable)
    case capacityExceeded(key: AnyHashable, maximum: Int)
    case internalError(description: String)
}

/// A dictionary where each key maps to a collection with a maximum capacity.
///
/// This allows setting different capacity limits for different keys.
/// When the limit is reached for a key, adding more elements will throw an error.
struct LimitedCollectionDictionary<Key: Hashable, Element> {
    private(set) var capacityLimits: [Key: Int] = [:]
    private(set) var collections: [Key: LimitedCollection<Element>] = [:]

    /// Sets the maximum number of elements allowed for a key
    /// - Parameters:
    ///   - limit: Maximum number of elements
    ///   - key: The key to configure
    /// - Throws: Error if the collection cannot be updated
    mutating func setCapacityLimit(_ limit: Int, forKey key: Key) throws {
        capacityLimits[key] = limit

        if let existingCollection = collections[key] {
            var newCollection = LimitedCollection<Element>(capacity: limit)
            try newCollection.append(contentsOf: existingCollection.all)
            collections[key] = newCollection
        }
    }

    /// Removes capacity restrictions for a key
    /// - Parameter key: The key to make unlimited
    mutating func setUnlimitedCapacity(forKey key: Key) {
        capacityLimits.removeValue(forKey: key)
        collections.removeValue(forKey: key)
    }

    /// Adds a single element to a key's collection if within capacity
    /// - Parameters:
    ///   - element: Element to add
    ///   - key: Target key
    /// - Throws: Error if capacity is exceeded or collection cannot be accessed
    mutating func append(_ element: Element, forKey key: Key) throws {
        if collections[key] == nil {
            let limit = getCapacityLimit(forKey: key)
            collections[key] = LimitedCollection<Element>(capacity: limit)
        }
        
        guard var collection = collections[key] else {
            throw LimitedCollectionDictionaryError.internalError(description: "Failed to access collection for key \(key)")
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

    /// Determines the capacity limit for a key based on configuration
    /// - Parameter key: Key to check
    /// - Returns: Specific limit or Int.max for unlimited
    private func getCapacityLimit(forKey key: Key) -> Int {
        if let limit = capacityLimits[key] {
            return limit
        }

        return Int.max
    }
} 
