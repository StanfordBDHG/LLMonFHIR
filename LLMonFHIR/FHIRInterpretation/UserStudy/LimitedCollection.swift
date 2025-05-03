//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Error when too many elements are added
enum LimitedCollectionError: Error {
    case capacityExceeded(maximum: Int)
}

// periphery:ignore - These are fundamental APIs for collection handling, even if not all are used in every context.

/// A collection with a maximum capacity that throws an error when full
struct LimitedCollection<Element> {
    private let capacity: Int

    private var elements: [Element] = []

    /// Number of elements in the collection
    var count: Int {
        elements.count
    }

    /// Check if collection has no elements
    var isEmpty: Bool {
        elements.isEmpty
    }

    /// Get all elements as an array
    var all: [Element] {
        elements
    }


    /// Create a new collection with a maximum size
    /// - Parameter capacity: Maximum number of elements allowed
    init(capacity: Int) {
        self.capacity = capacity
    }


    /// Add a new element if capacity allows
    /// - Parameter element: Element to add
    /// - Throws: Error if collection is full
    mutating func append(_ element: Element) throws {
        guard elements.count < capacity else {
            throw LimitedCollectionError.capacityExceeded(maximum: capacity)
        }
        elements.append(element)
    }

    /// Add multiple elements if capacity allows
    /// - Parameter newElements: Elements to add
    /// - Throws: Error if adding would exceed capacity
    mutating func append<S: Sequence>(contentsOf newElements: S) throws where S.Element == Element {
        let newElementsArray = Array(newElements)
        guard elements.count + newElementsArray.count <= capacity else {
            throw LimitedCollectionError.capacityExceeded(maximum: capacity)
        }
        elements.append(contentsOf: newElementsArray)
    }

    /// Remove all elements
    mutating func removeAll() {
        elements.removeAll()
    }

    /// Remove an element at a specific position
    /// - Parameter index: Position to remove from
    /// - Returns: The removed element
    @discardableResult
    mutating func remove(at index: Int) -> Element {
        elements.remove(at: index)
    }

    /// Access element by position
    subscript(index: Int) -> Element {
        elements[index]
    }
}

extension LimitedCollection: Collection {
    typealias Index = Int

    var startIndex: Int {
        elements.startIndex
    }

    var endIndex: Int {
        elements.endIndex
    }

    // swiftlint:disable:next identifier_name
    func index(after i: Int) -> Int {
        elements.index(after: i)
    }
}
