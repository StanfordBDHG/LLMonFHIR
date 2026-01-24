//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation


extension TaskQuestionType {
    public struct AnswerOptions: Hashable, RandomAccessCollection, ExpressibleByArrayLiteral, Sendable {
        private let storage: [String]
        
        public var startIndex: Int {
            storage.startIndex
        }
        public var endIndex: Int {
            storage.endIndex
        }
        
        public init(_ other: some Sequence<String>) {
            storage = Array(other)
        }
        
        public init(arrayLiteral elements: String...) {
            storage = elements
        }
        
        public subscript(position: Int) -> String {
            storage[position]
        }
    }
}


extension TaskQuestionType.AnswerOptions: Codable {
    public var stringValue: String {
        if let key = Self.presets.first(where: { $0.value == self })?.key {
            "<\(key)>"
        } else {
            storage.joined(separator: ";")
        }
    }
    
    public init(stringValue string: some StringProtocol) {
        if string.first == "<", string.last == ">", let preset = Self.presets[String(string.dropFirst().dropLast())] {
            self = preset
        } else {
            self.init(string.split(separator: ";").map { $0.trimmingWhitespace() })
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self.init(stringValue: stringValue)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}


extension TaskQuestionType.AnswerOptions {
    public static let presets: [String: Self] = [
        "clarityScale": clarityScale,
        "effectivenessScale": effectivenessScale,
        "confidentnessScale": confidentnessScale,
        "comparisonScale": comparisonScale,
        "balancedEaseScale": balancedEaseScale,
        "frequencyOptions": frequencyOptions
    ]
    
    public static let clarityScale: Self = [
        "Very clear",
        "Somewhat clear",
        "Neither clear nor unclear",
        "Somewhat unclear",
        "Very unclear"
    ]

    public static let effectivenessScale: Self = [
        "Very effective",
        "Somewhat effective",
        "Neither clear nor unclear",
        "Somewhat ineffective",
        "Very ineffective"
    ]
    
    public static let confidentnessScale: Self = [
        "Very confident",
        "Somewhat confident",
        "Neither confident nor unconfident",
        "Somewhat unconfident",
        "Very unconfident"
    ]

    public static let comparisonScale: Self = [
        "Significantly better",
        "Slightly better",
        "No change",
        "Slightly worse",
        "Significantly worse"
    ]

    public static let balancedEaseScale: Self = [
        "Very easy",
        "Somewhat easy",
        "Neither easy nor difficult",
        "Somewhat difficult",
        "Very difficult"
    ]

    public static let frequencyOptions: Self = [
        "Always",
        "Often",
        "Sometimes",
        "Rarely",
        "Never"
    ]
}
