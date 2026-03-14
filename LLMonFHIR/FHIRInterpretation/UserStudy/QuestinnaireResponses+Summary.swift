//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

import Foundation
import SpeziLLM
import SpeziLLMOpenAI
import SpeziQuestionnaire
import class UIKit.UIImage
import func QuartzCore.CACurrentMediaTime


extension QuestionnaireResponses {
    func summarize(using runner: LLMRunner) async throws -> String {
        let taskSummaries: [(Questionnaire.Task, String)] = try await withThrowingTaskGroup(
            of: (Int, Questionnaire.Task, String?).self
        ) { taskGroup in
            var idx = 0
            for section in questionnaire.sections {
                for task in section.tasks {
                    defer {
                        idx += 1
                    }
                    let response = self.responses[task.id]
                    taskGroup.addTask { [idx] in
                        (idx, task, try await response.summarize(for: task, using: runner))
                    }
                }
            }
            return try await taskGroup
                .reduce(into: [(Int, Questionnaire.Task, String?)]()) { $0.append($1) }
                .sorted { $0.0 < $1.0 }
                .compactMap { (_, task, summary) in summary.map { (task, $0) } }
        }
        var summary = "The following is a summary of the user's responses to the intake questionnaire:\n"
        for (task, taskSummary) in taskSummaries {
            summary.append("\n\nQUESTION: \(task.title)")
            summary.append("\nANSWER: \(taskSummary)")
        }
        return summary
    }
}


extension QuestionnaireResponses.Response {
    fileprivate func summarize(for task: Questionnaire.Task, using runner: LLMRunner) async throws -> String? {
        guard !value.isEmpty else {
            return nil
        }
        switch value {
        case .none:
            return nil
        case .string(let value):
            return value
        case .bool(let value):
            return value ? "Yes" : "No"
        case .date(let components):
            guard case .dateTime(let config) = task.kind, let date = Calendar.current.date(from: components) else {
                return nil
            }
            return switch config.style {
            case .timeOnly:
                date.formatted(date: .omitted, time: .complete)
            case .dateOnly:
                date.formatted(date: .complete, time: .omitted)
            case .dateAndTime:
                date.formatted(date: .complete, time: .complete)
            }
        case .number(let value):
            return "\(value)"
        case .choice(let response):
            guard !response.selectedOptions.isEmpty || response.freeTextOtherResponse != nil else {
                return nil
            }
            guard case .choice(let config) = task.kind else {
                return nil
            }
            var options = response.selectedOptions.compactMap { id in
                config.options.first { $0.id == id }?.title
            }
            if let freeTextOtherResponse = response.freeTextOtherResponse {
                options.append(freeTextOtherResponse)
            }
            return options
                // in case an option title contains a comma
                .map { "'\($0)'" }
                .joined(separator: ", ")
        case .attachments:
            // currently not used by any LLMonFHIR intake questionnaires
            fatalError("Not Yet Implemented")
        case .custom(let value):
            return switch value {
            case let value as QuestionnaireResponses.AnnotatedImage:
                try await value.summarize(for: task, using: runner)
            default:
                nil
            }
        }
    }
}


extension QuestionnaireResponses.AnnotatedImage {
    fileprivate func summarize(for task: Questionnaire.Task, using runner: LLMRunner) async throws -> String? {
        /// 0 = max compression; 1 = no compression
        let jpegCompression: Double = 1
        /// The LLMSchema used for the image summary queries
        let schema = LLMOpenAISchema(parameters: .init(modelType: .gpt4o))
        
        guard case .annotateImage(let config) = task.kind else {
            return nil
        }
        
        guard let baseImage = config.inputImage.image(),
              let annotatedImage = self.draw(onto: baseImage) else {
            return nil
        }
        
        let pipelineExplanation = """
            You operate as part of an image analysis pipeline, where an image annotated by a user is interpreted using an LLM.
            The user was presented an image, in an iOS app, and asked to draw onto the image, to annotate (highlight) regions where a certain condition is true
            (e.g. "mark all areas where you feel pain in red").
            
            The pipeline is as follows:
            1. Base image description:
                - job: produces a textual description of the unannotated image, for use as input into an LLM
                - input: the unannotated image
                - output: a textual description of the input image, for use as input into an LLM
            2. Annotated image description:
                - job: produces a textual description of the annotated image, for use as input into an LLM
                - input:
                    - the output from step 1 (ie, the description of the unannotated image)
                    - the annotated image
                - output:
                    a textual description of the annotated image, taking into account the image itself and the description of the unannotated version of the image), for use as input into an LLM
                    when producing this output, keep in mind that the LLM for step 3 (where the output will be used as input) won't have access to either of the images. phrase the explanation in a way that is understandable without also requiring access to the image.
            3. Further Processing
                - job: answer questions based on the information available in the annotated image (ie, based on which regions of the image the user highlighted)
                - input:
                    - the output from step 2 (the textual description of the annotated/highlighted image)
                    - the user's question
                - output: a response to the user's question, taking into account the context generated by step 2, and other context passed along.
            
            """
        
        print("will run base img expl")
        let baseImgExplStart = CACurrentMediaTime()
        let baseImageExplanation: String = try await runner.oneShot(with: schema, context: [
            LLMContextEntity(
                role: .system,
                content: pipelineExplanation + "\n\nYour place in the pipeline is step 1, i.e. the analysis of the unannotated, original image"
            ),
            try LLMContextEntity(role: .user, image: baseImage, jpegCompressionFactor: jpegCompression).unwrap("Unable to build LLM context")
        ])
        print("BASE IMAGE DESC: '\(baseImageExplanation)' (took \(CACurrentMediaTime() - baseImgExplStart) sec)")
        
        print("\n\nwill run annot img expl")
        let annotImgExplStart = CACurrentMediaTime()
        let annotatedImageExplanation: String = try await runner.oneShot(with: schema, context: [
            LLMContextEntity(
                role: .system,
                content: pipelineExplanation + "\n\nYour place in the pipeline is step 2, i.e. the analysis of the annotated image, taking into account the description of the unedited original image"
            ),
            LLMContextEntity(role: .system, content: "The description of the original input image is as follows: '\(baseImageExplanation)'"),
            try LLMContextEntity(role: .user, image: annotatedImage, jpegCompressionFactor: jpegCompression).unwrap("Unable to build LLM context")
        ])
        print("ANNOT IMAGE DESC: '\(annotatedImageExplanation)' (took \(CACurrentMediaTime() - annotImgExplStart) sec)")
        
        return annotatedImageExplanation
    }
}


extension Optional {
    fileprivate func unwrap(_ errorMsg: @autoclosure () -> String) throws -> Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            throw NSError(domain: "edu.stanford.LLMonFHIR", code: 0, userInfo: [
                NSLocalizedDescriptionKey: errorMsg()
            ])
        }
    }
}


//extension ModelsR4.QuestionnaireResponse {
//    func summary(basedOn questionnaire: Questionnaire) -> String {
//        let indexedItems = questionnaire.indexedItemsByLinkId
//        var lines: [String] = []
//        lines.reserveCapacity((item?.count ?? 0) * 2)
//        appendSummaryLines(from: item ?? [], indexedItems: indexedItems, into: &lines)
//        return lines.joined(separator: "\n")
//    }
//}
//
//
//extension ModelsR4.Questionnaire {
//    fileprivate var indexedItemsByLinkId: [FHIRPrimitive<FHIRString>: QuestionnaireItem] {
//        Self.indexItemsByLinkId(item ?? [])
//    }
//
//    private static func indexItemsByLinkId(
//        _ items: [QuestionnaireItem]
//    ) -> [FHIRPrimitive<FHIRString>: QuestionnaireItem] {
//        var indexed: [FHIRPrimitive<FHIRString>: QuestionnaireItem] = [:]
//        for item in items {
//            indexed[item.linkId] = item
//            if let nestedItems = item.item, !nestedItems.isEmpty {
//                let nestedIndex = indexItemsByLinkId(nestedItems)
//                for (key, value) in nestedIndex {
//                    indexed[key] = value
//                }
//            }
//        }
//        return indexed
//    }
//}
//
//
//extension ModelsR4.QuestionnaireResponse {
//    fileprivate func appendSummaryLines(
//        from responseItems: [QuestionnaireResponseItem],
//        indexedItems: [FHIRPrimitive<FHIRString>: QuestionnaireItem],
//        into lines: inout [String]
//    ) {
//        for responseItem in responseItems {
//            let questionnaireItem = indexedItems[responseItem.linkId]
//            let questionText = responseItem.questionText(fallbackItem: questionnaireItem)
//            if let answers = responseItem.answer, !answers.isEmpty {
//                let formattedAnswers = answers.compactMap(\.formattedValue)
//                if formattedAnswers.isEmpty {
//                    lines.append("\(questionText): (no readable answer)")
//                } else {
//                    lines.append("\(questionText): \(formattedAnswers.joined(separator: "; "))")
//                }
//                for answer in answers {
//                    if let nestedItems = answer.item, !nestedItems.isEmpty {
//                        appendSummaryLines(from: nestedItems, indexedItems: indexedItems, into: &lines)
//                    }
//                }
//            } else {
//                lines.append("\(questionText): (no answer)")
//            }
//            if let nestedItems = responseItem.item, !nestedItems.isEmpty {
//                appendSummaryLines(from: nestedItems, indexedItems: indexedItems, into: &lines)
//            }
//        }
//    }
//}
//
//
//extension ModelsR4.QuestionnaireResponseItem {
//    fileprivate func questionText(fallbackItem: QuestionnaireItem?) -> String {
//        if let text = fallbackItem?.text?.stringValue?.trimmedNonEmpty {
//            return text
//        }
//
//        if let linkIdString = linkId.stringValue?.trimmedNonEmpty {
//            return linkIdString
//        }
//
//        return "Question"
//    }
//}
//
//
//extension ModelsR4.QuestionnaireResponseItemAnswer {
//    /// Human-readable answer value; intentionally avoids exposing `code` and `system`.
//    fileprivate var formattedValue: String? {
//        guard let value else {
//            return nil
//        }
//
//        switch value {
//        case .boolean(let primitive):
//            guard let boolValue = primitive.value?.bool else {
//                return nil
//            }
//            return boolValue ? "Yes" : "No"
//        case .integer(let primitive):
//            guard let intValue = primitive.value?.integer else {
//                return nil
//            }
//            return String(intValue)
//        case .decimal(let primitive):
//            guard let decimalValue = primitive.value else {
//                return nil
//            }
//            return String(describing: decimalValue)
//        case .string(let primitive):
//            return primitive.stringValue?.trimmedNonEmpty
//        case .date(let primitive):
//            return primitive.value.map { String(describing: $0) }
//        case .dateTime(let primitive):
//            return primitive.value.map { String(describing: $0) }
//        case .time(let primitive):
//            return primitive.value.map { String(describing: $0) }
//        case .uri(let primitive):
//            return primitive.value.map { String(describing: $0) }
//        case .coding(let coding):
//            return coding.display?.stringValue?.trimmedNonEmpty
//        case .quantity(let quantity):
//            return quantity.formattedValue
//        case .reference(let reference):
//            if let display = reference.display?.stringValue?.trimmedNonEmpty {
//                return display
//            }
//            if let ref = reference.reference?.stringValue?.trimmedNonEmpty {
//                return ref
//            }
//            return nil
//        case .attachment(let attachment):
//            if let title = attachment.title?.stringValue?.trimmedNonEmpty {
//                return title
//            }
//            if let url = attachment.url?.value {
//                return String(describing: url)
//            }
//            return nil
//        }
//    }
//}
//
//
//extension ModelsR4.Quantity {
//    fileprivate var formattedValue: String? {
//        let valueString = value?.value.map { String(describing: $0) }
//        let unitString = unit?.stringValue?.trimmedNonEmpty
//
//        switch (valueString, unitString) {
//        case let (value?, unit?):
//            return "\(value) \(unit)"
//        case let (value?, nil):
//            return value
//        default:
//            return nil
//        }
//    }
//}
//
//
//extension ModelsR4.FHIRPrimitive where PrimitiveType == ModelsR4.FHIRString {
//    fileprivate var stringValue: String? {
//        value?.string
//    }
//}
//
//
//extension String {
//    fileprivate var trimmedNonEmpty: String? {
//        let trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//        return trimmed.isEmpty ? nil : trimmed
//    }
//}
