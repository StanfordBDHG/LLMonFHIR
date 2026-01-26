//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ModelsR4


extension QuestionnaireResponse {
    func summary(basedOn questionnaire: Questionnaire) -> String {
        let indexedItems = questionnaire.indexedItemsByLinkId
        var lines: [String] = []
        lines.reserveCapacity((item?.count ?? 0) * 2)

        appendSummaryLines(from: item ?? [], indexedItems: indexedItems, into: &lines)

        return lines.joined(separator: "\n")
    }
}


extension Questionnaire {
    fileprivate var indexedItemsByLinkId: [FHIRPrimitive<FHIRString>: QuestionnaireItem] {
        Self.indexItemsByLinkId(item ?? [])
    }

    private static func indexItemsByLinkId(
        _ items: [QuestionnaireItem]
    ) -> [FHIRPrimitive<FHIRString>: QuestionnaireItem] {
        var indexed: [FHIRPrimitive<FHIRString>: QuestionnaireItem] = [:]

        for item in items {
            indexed[item.linkId] = item

            if let nestedItems = item.item, !nestedItems.isEmpty {
                let nestedIndex = indexItemsByLinkId(nestedItems)
                for (key, value) in nestedIndex {
                    indexed[key] = value
                }
            }
        }

        return indexed
    }
}


extension QuestionnaireResponse {
    fileprivate func appendSummaryLines(
        from responseItems: [QuestionnaireResponseItem],
        indexedItems: [FHIRPrimitive<FHIRString>: QuestionnaireItem],
        into lines: inout [String]
    ) {
        for responseItem in responseItems {
            let questionnaireItem = indexedItems[responseItem.linkId]
            let questionText = responseItem.questionText(fallbackItem: questionnaireItem)

            if let answers = responseItem.answer, !answers.isEmpty {
                let formattedAnswers = answers.compactMap(\.formattedValue)

                if formattedAnswers.isEmpty {
                    lines.append("\(questionText): (no readable answer)")
                } else {
                    lines.append("\(questionText): \(formattedAnswers.joined(separator: "; "))")
                }

                for answer in answers {
                    if let nestedItems = answer.item, !nestedItems.isEmpty {
                        appendSummaryLines(from: nestedItems, indexedItems: indexedItems, into: &lines)
                    }
                }
            } else {
                lines.append("\(questionText): (no answer)")
            }

            if let nestedItems = responseItem.item, !nestedItems.isEmpty {
                appendSummaryLines(from: nestedItems, indexedItems: indexedItems, into: &lines)
            }
        }
    }
}


extension QuestionnaireResponseItem {
    fileprivate func questionText(fallbackItem: QuestionnaireItem?) -> String {
        if let text = fallbackItem?.text?.stringValue?.trimmedNonEmpty {
            return text
        }

        if let linkIdString = linkId.stringValue?.trimmedNonEmpty {
            return linkIdString
        }

        return "Question"
    }
}


extension QuestionnaireResponseItemAnswer {
    /// Human-readable answer value; intentionally avoids exposing `code` and `system`.
    fileprivate var formattedValue: String? {
        guard let value else {
            return nil
        }

        switch value {
        case .boolean(let primitive):
            guard let boolValue = primitive.value?.bool else {
                return nil
            }
            return boolValue ? "Yes" : "No"
        case .integer(let primitive):
            guard let intValue = primitive.value?.integer else {
                return nil
            }
            return String(intValue)
        case .decimal(let primitive):
            guard let decimalValue = primitive.value else {
                return nil
            }
            return String(describing: decimalValue)
        case .string(let primitive):
            return primitive.stringValue?.trimmedNonEmpty
        case .date(let primitive):
            return primitive.value.map { String(describing: $0) }
        case .dateTime(let primitive):
            return primitive.value.map { String(describing: $0) }
        case .time(let primitive):
            return primitive.value.map { String(describing: $0) }
        case .uri(let primitive):
            return primitive.value.map { String(describing: $0) }
        case .coding(let coding):
            return coding.display?.stringValue?.trimmedNonEmpty
        case .quantity(let quantity):
            return quantity.formattedValue
        case .reference(let reference):
            if let display = reference.display?.stringValue?.trimmedNonEmpty {
                return display
            }
            if let ref = reference.reference?.stringValue?.trimmedNonEmpty {
                return ref
            }
            return nil
        case .attachment(let attachment):
            if let title = attachment.title?.stringValue?.trimmedNonEmpty {
                return title
            }
            if let url = attachment.url?.value {
                return String(describing: url)
            }
            return nil
        }
    }
}


extension Quantity {
    fileprivate var formattedValue: String? {
        let valueString = value?.value.map { String(describing: $0) }
        let unitString = unit?.stringValue?.trimmedNonEmpty

        switch (valueString, unitString) {
        case let (value?, unit?):
            return "\(value) \(unit)"
        case let (value?, nil):
            return value
        default:
            return nil
        }
    }
}


extension FHIRPrimitive where PrimitiveType == FHIRString {
    fileprivate var stringValue: String? {
        value?.string
    }
}


extension String {
    fileprivate var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
