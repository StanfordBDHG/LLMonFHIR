//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Represents a user's response to a survey question
enum TaskQuestionAnswer: Hashable, Sendable {
    case scale(Int)
    case freeText(String)
    case netPromoterScore(Int)
    case unanswered
    
    var rawValue: String {
        switch self {
        case .scale(let value):
            "\(value)"
        case .freeText(let value):
            "\(value)"
        case .netPromoterScore(let value):
            "\(value)"
        case .unanswered:
            "unanswered"
        }
    }
}


extension TaskQuestionAnswer {
    init?(from string: String, for questionKind: TaskQuestionType) {
        if string == Self.unanswered.rawValue {
            self = .unanswered
            return
        }
        switch questionKind {
        case .instructional:
            self = .unanswered
        case .scale:
            guard let intValue = Int(string) else {
                return nil
            }
            self = .scale(intValue)
        case .netPromoterScore:
            guard let intValue = Int(string) else {
                return nil
            }
            self = .netPromoterScore(intValue)
        case .freeText:
            self = .freeText(string)
        }
    }
}


extension TaskQuestionAnswer: Encodable, DecodableWithConfiguration {
    struct DecodingConfiguration {
        let questionKind: TaskQuestionType
    }
    
    init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if let value = Self(from: rawValue, for: configuration.questionKind) {
            self = value
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid input '\(rawValue)'"))
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
