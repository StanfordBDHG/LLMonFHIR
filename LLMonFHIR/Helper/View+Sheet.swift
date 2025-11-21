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

extension View {
    func sheet<Item, ID: Hashable>(
        item: Binding<Item?>,
        id: KeyPath<Item, ID>,
        onDismiss: (@MainActor () -> Void)? = nil,
        @ViewBuilder content: @MainActor @escaping (Item) -> some View
    ) -> some View {
        let binding = Binding<IdentifiableAdaptor<Item, ID>?> {
            if let item = item.wrappedValue {
                IdentifiableAdaptor(value: item, keyPath: id)
            } else {
                nil
            }
        } set: { newValue in
            if let newValue {
                item.wrappedValue = newValue.value
            } else {
                item.wrappedValue = nil
            }
        }
        return self.sheet(item: binding, onDismiss: onDismiss) { item in
            content(item.value)
        }
    }
}
