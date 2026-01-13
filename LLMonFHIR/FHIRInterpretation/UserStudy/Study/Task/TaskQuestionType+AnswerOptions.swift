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
    struct AnswerOptions: Hashable, RandomAccessCollection, ExpressibleByArrayLiteral, Sendable {
        private let storage: [String]
        
        var startIndex: Int {
            storage.startIndex
        }
        var endIndex: Int {
            storage.endIndex
        }
        
        init(_ other: some Sequence<String>) {
            storage = Array(other)
        }
        
        init(arrayLiteral elements: String...) {
            storage = elements
        }
        
        subscript(position: Int) -> String {
            storage[position]
        }
    }
}


extension TaskQuestionType.AnswerOptions: Codable {
    var stringValue: String {
        if let key = Self.presets.first(where: { $0.value == self })?.key {
            "<\(key)>"
        } else {
            storage.joined(separator: ";")
        }
    }
    
    init(stringValue string: some StringProtocol) {
        if string.first == "<", string.last == ">", let preset = Self.presets[String(string.dropFirst().dropLast())] {
            self = preset
        } else {
            self.init(string.split(separator: ";").map { $0.trimmingWhitespace() })
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self.init(stringValue: stringValue)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}


extension TaskQuestionType.AnswerOptions {
    static let presets: [String: Self] = [
        "clarityScale": clarityScale,
        "effectivenessScale": effectivenessScale,
        "confidentnessScale": confidentnessScale,
        "comparisonScale": comparisonScale,
        "balancedEaseScale": balancedEaseScale,
        "frequencyOptions": frequencyOptions
    ]
    
    static let clarityScale: Self = [
        "Very clear",
        "Somewhat clear",
        "Neither clear nor unclear",
        "Somewhat unclear",
        "Very unclear"
    ]

    static let effectivenessScale: Self = [
        "Very effective",
        "Somewhat effective",
        "Neither clear nor unclear",
        "Somewhat ineffective",
        "Very ineffective"
    ]
    
    static let confidentnessScale: Self = [
        "Very confident",
        "Somewhat confident",
        "Neither confident nor unconfident",
        "Somewhat unconfident",
        "Very unconfident"
    ]

    static let comparisonScale: Self = [
        "Significantly better",
        "Slightly better",
        "No change",
        "Slightly worse",
        "Significantly worse"
    ]

    static let balancedEaseScale: Self = [
        "Very easy",
        "Somewhat easy",
        "Neither easy nor difficult",
        "Somewhat difficult",
        "Very difficult"
    ]

    static let frequencyOptions: Self = [
        "Always",
        "Often",
        "Sometimes",
        "Rarely",
        "Never"
    ]
}
