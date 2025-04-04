//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFHIR


extension SpeziFHIR.FHIRResource: @retroactive Encodable {
    struct AnyEncodable: Encodable {
        private let value: Any

        init(_ value: Any) {
            self.value = value
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch value {
            case let string as String:
                try container.encode(string)
            case let int as Int:
                try container.encode(int)
            case let double as Double:
                try container.encode(double)
            case let bool as Bool:
                try container.encode(bool)
            case let array as [Any]:
                try container.encode(array.map { AnyEncodable($0) })
            case let dict as [String: Any]:
                try container.encode(dict.mapValues { AnyEncodable($0) })
            case is NSNull, Optional<Any>.none:
                try container.encodeNil()
            default:
                try container.encode(String(describing: value))
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        guard
            let jsonData = jsonDescription.data(using: .utf8),
            let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            return
        }

        let encodableDict = jsonDict.mapValues { AnyEncodable($0) }

        var container = encoder.singleValueContainer()
        try container.encode(encodableDict)
    }
}
