//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


private struct IdentifiableAdaptor<Value, ID: Hashable>: Identifiable {
    let value: Value
    let keyPath: KeyPath<Value, ID>
    
    var id: ID {
        value[keyPath: keyPath]
    }
}


extension Binding {
    @MainActor
    fileprivate init<Item, ID: Hashable>(_ other: Binding<Item?>, id: KeyPath<Item, ID>) where Value == IdentifiableAdaptor<Item, ID>? {
        self.init {
            if let item = other.wrappedValue {
                IdentifiableAdaptor(value: item, keyPath: id)
            } else {
                nil
            }
        } set: { newValue in
            if let newValue {
                other.wrappedValue = newValue.value
            } else {
                other.wrappedValue = nil
            }
        }
    }
}


extension View {
    func sheet<Item, ID: Hashable>(
        item: Binding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (@MainActor () -> Void)? = nil,
        @ViewBuilder content: @MainActor @escaping (Item) -> some View
    ) -> some View {
        self.sheet(item: Binding(item, id: id), onDismiss: onDismiss) { item in
            content(item.value)
        }
    }
    
    
    func fullScreenCover<Item, ID: Hashable>(
        item: Binding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (@MainActor () -> Void)? = nil,
        @ViewBuilder content: @MainActor @escaping (Item) -> some View
    ) -> some View {
        self.fullScreenCover(item: Binding(item, id: id), onDismiss: onDismiss) { item in
            content(item.value)
        }
    }
}
