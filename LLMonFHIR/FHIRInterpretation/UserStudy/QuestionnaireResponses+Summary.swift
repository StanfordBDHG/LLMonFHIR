//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LLMonFHIRShared
import SpeziLLM
import SpeziLLMOpenAI
import SpeziQuestionnaire
import class UIKit.UIImage


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
                    taskGroup.addTask { [idx, questionnaire] in
                        (idx, task, try await response.summarize(for: task, in: questionnaire, using: runner))
                    }
                }
            }
            return try await taskGroup
                .reduce(into: [(Int, Questionnaire.Task, String?)]()) { $0.append($1) }
                .sorted { $0.0 < $1.0 }
                .compactMap { _, task, summary in summary.map { (task, $0) } }
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
    fileprivate func summarize( // swiftlint:disable:this cyclomatic_complexity
        for task: Questionnaire.Task,
        in questionnaire: Questionnaire,
        using runner: LLMRunner
    ) async throws -> String? {
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
            // Not Yet Implemented
            return nil
        case .custom(let value):
            return switch value {
            case let value as QuestionnaireResponses.ImageAnnotation:
                try await value.summarize(for: task, in: questionnaire, using: runner)
            default:
                nil
            }
        }
    }
}


extension QuestionnaireResponses.ImageAnnotation {
    fileprivate func summarize( // swiftlint:disable:this function_body_length
        for task: Questionnaire.Task,
        in questionnaire: Questionnaire,
        using runner: LLMRunner
    ) async throws -> String? {
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
        if questionnaire == (try? Study.spineAI.initialQuestionnaire(from: .main)).flatMap({ try? Questionnaire($0) }),
           config.inputImage == .namedInMainBundle(filename: "bodymap.png"),
           let labeledImageUrl = Bundle.main.url(forResource: "bodymap+labels", withExtension: "png"),
           let labeledImage = UIImage(contentsOfFile: labeledImageUrl.absoluteURL.path) {
            return try await runner.oneShot(with: schema, context: [
                LLMContextEntity(role: .system, content: """
                    Analyze the two images provided:
                    1. A dermatome reference map of the body
                    2. A body diagram annotated by a patient indicating areas of pain.
                    
                    Identify and describe the regions marked by the patient. Specify:
                    - body side (left/right), view (front/back), and anatomical region,
                    - approximate dermatomes involved (e.g., C6, L5, S1),
                    - whether the pattern appears dermatomal or non-dermatomal.
                    
                    Based on the dermatome mapping, infer the most likely affected spinal nerve roots. Make it an objective assessment, don't interpret any of the annotations. If multiple dermatomes are involved, list them and describe the overall distribution.
                    
                    Output a concise clinical-style summary (3–6 sentences) describing the pain location and dermatomal correspondence. If the markings do not match a clear dermatome pattern, state that explicitly. Ignore markings outside of the body.
                    """),
                LLMContextEntity(_role: .system, image: labeledImage, format: .jpeg(compressionFactor: jpegCompression)).unwrap(""),
                LLMContextEntity(_role: .user, image: annotatedImage, format: .jpeg(compressionFactor: jpegCompression)).unwrap("")
            ])
        } else {
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
            let baseImageExplanation: String = try await runner.oneShot(with: schema, context: [
                LLMContextEntity(
                    role: .system,
                    content: pipelineExplanation + "\n\nYour place in the pipeline is step 1, i.e. the analysis of the unannotated, original image"
                ),
                try LLMContextEntity(_role: .user, image: baseImage, format: .jpeg(compressionFactor: jpegCompression))
                    .unwrap("Unable to build LLM context")
            ])
            let annotatedImageExplanation: String = try await runner.oneShot(with: schema, context: [
                LLMContextEntity(
                    role: .system,
                    // swiftlint:disable:next line_length
                    content: pipelineExplanation + "\n\nYour place in the pipeline is step 2, i.e. the analysis of the annotated image, taking into account the description of the unedited original image"
                ),
                LLMContextEntity(role: .system, content: "The description of the original input image is as follows: '\(baseImageExplanation)'"),
                try LLMContextEntity(_role: .user, image: annotatedImage, format: .jpeg(compressionFactor: jpegCompression))
                    .unwrap("Unable to build LLM context")
            ])
            return annotatedImageExplanation
        }
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
