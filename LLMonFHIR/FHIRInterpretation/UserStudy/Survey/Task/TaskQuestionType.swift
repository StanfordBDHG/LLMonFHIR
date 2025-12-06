//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Defines the type of question and its validation rules
enum TaskQuestionType: Hashable, Sendable {
    case scale(responseOptions: AnswerOptions)
    case freeText
    case netPromoterScore(range: ClosedRange<Int>)

    var range: ClosedRange<Int>? {
        switch self {
        case .scale(let responseOptions):
            return 1...(responseOptions.count)
        case .netPromoterScore(let range):
            return range
        case .freeText:
            return nil
        }
    }
}


extension TaskQuestionType: Codable {
    private enum ParsingError: Error {
        case unknownType
        case invalidInput
    }
    
    private var stringValue: String {
        switch self {
        case .freeText:
            "text"
        case .scale(let options):
            "scale(\(options.stringValue))"
        case .netPromoterScore(let range):
            "NPS(\(range.lowerBound);\(range.upperBound))"
        }
    }
    
    private init(stringValue string: String) throws(ParsingError) {
        let rawOptions = { () throws(ParsingError) -> Substring in
            guard let startIdx = string.firstIndex(of: "("), string.last == ")" else {
                throw ParsingError.invalidInput
            }
            return string[string.index(after: startIdx)...].dropLast()
        }
        if string == "text" {
            self = .freeText
        } else if string.starts(with: "scale") {
            self = .scale(responseOptions: AnswerOptions(stringValue: try rawOptions()))
        } else if string.starts(with: "NPS") {
            let rawOptions = try rawOptions()
            let components = rawOptions.split(separator: ";").compactMap { Int($0) }
            guard components.count == 2 else {
                throw .invalidInput
            }
            self = .netPromoterScore(range: components[0]...components[1])
        } else {
            throw .unknownType
        }
    }
    
    init(from decoder: any Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        try self.init(stringValue: stringValue)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}


extension ClosedRange where Bound == Int {
    var llmOnFhirStringValue: String {
        "\(lowerBound);\(upperBound)"
    }
    
    init?(llmOnFhirStringValue string: some StringProtocol) {
        let components = string.split(separator: ";")
        guard components.count == 2 else {
            return nil
        }
        guard let lower = Int(components[0]), let upper = Int(components[1]) else {
            return nil
        }
        self = lower...upper
    }
}
