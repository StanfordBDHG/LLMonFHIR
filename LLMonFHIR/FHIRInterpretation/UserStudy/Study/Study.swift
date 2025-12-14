//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable redundant_string_enum_value

import CryptoKit
import Foundation


@available(*, deprecated, renamed: "Study")
typealias Survey = Study


/// Manages a collection of survey tasks and their responses
final class Study: Identifiable {
    /// The survey's unique identifier.
    let id: String
    /// The survey's title.
    let title: String
    /// A brief explainer detailing what the survey does.
    let explainer: String
    /// The OpenAI API key that should be used when answering this survey.
    let openAIAPIKey: String
    /// The email address to which the report file should be sent.
    let reportEmail: String?
    
    /// The public key to use when encrypting a report file.
    ///
    /// `nil` if the files should never be encrypted.
    let encryptionKey: Curve25519.KeyAgreement.PublicKey?
    
    /// The tasks that make up this survey
    private(set) var tasks: [SurveyTask]
    
    /// Creates a new survey.
    init(
        id: String,
        title: String,
        explainer: String,
        openAIAPIKey: String,
        reportEmail: String?,
        encryptionKey: Curve25519.KeyAgreement.PublicKey?,
        tasks: [SurveyTask]
    ) {
        self.id = id
        self.title = title
        self.explainer = explainer
        self.openAIAPIKey = openAIAPIKey
        self.reportEmail = reportEmail
        self.encryptionKey = encryptionKey
        self.tasks = tasks
    }
}


extension Study {
    /// Submits an answer for a specific question in a specific task
    /// - Parameters:
    ///   - answer: The answer to submit
    ///   - taskId: The ID of the task containing the question
    ///   - questionIndex: The index of the question within the task
    /// - Throws: `SurveyError` if the task or question cannot be found or the answer is invalid
    func submitAnswer(_ answer: TaskQuestionAnswer, forTaskId taskId: SurveyTask.ID, questionIndex: Int) throws {
        guard let groupIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw SurveyError.taskNotFound
        }
        try tasks[groupIndex].updateAnswer(answer, forQuestionIndex: questionIndex)
    }

    /// Resets all answers in the survey to unanswered
    func resetAllAnswers() {
        tasks = tasks.map { task in
            var newTask = task
            for index in newTask.questions.indices {
                try? newTask.updateAnswer(.unanswered, forQuestionIndex: index)
            }
            return newTask
        }
    }
}


// MARK: Survey + Codable

extension Study: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case explainer = "explainer"
        case tasks = "tasks"
        case openAIAPIKey = "openai_api_key"
        case reportEmail = "report_email"
        case encryptionKey = "encryption_key"
    }
    
    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            explainer: try container.decode(String.self, forKey: .explainer),
            openAIAPIKey: try container.decode(String.self, forKey: .openAIAPIKey),
            reportEmail: try container.decodeIfPresent(String.self, forKey: .reportEmail),
            encryptionKey: try container.decodeIfPresent(Data.self, forKey: .encryptionKey)
                .flatMap { $0.isEmpty ? nil : try .init(pemFileContents: $0) },
            tasks: try container.decode([SurveyTask].self, forKey: .tasks)
        )
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(explainer, forKey: .explainer)
        try container.encode(openAIAPIKey, forKey: .openAIAPIKey)
        try container.encodeIfPresent(reportEmail, forKey: .reportEmail)
        try container.encodeIfPresent(encryptionKey?.pemFileContents, forKey: .encryptionKey)
        try container.encode(tasks, forKey: .tasks)
    }
}


extension SurveyTask: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case instructions = "instructions"
        case assistantMessagesLimit = "assistantMessagesLimit"
        case questions = "questions"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            title: try container.decodeIfPresent(String.self, forKey: .title),
            instructions: try container.decodeIfPresent(String.self, forKey: .instructions),
            assistantMessagesLimit: try { () -> ClosedRange<Int>? in
                guard let string = try container.decodeIfPresent(String.self, forKey: .assistantMessagesLimit) else {
                    return nil
                }
                if let val = ClosedRange<Int>(llmOnFhirStringValue: string) {
                    return val
                } else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid input '\(string)'"))
                }
            }(),
            questions: try container.decode([TaskQuestion].self, forKey: .questions)
        )
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .id)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(assistantMessagesLimit?.llmOnFhirStringValue, forKey: .assistantMessagesLimit)
        try container.encode(questions, forKey: .questions)
    }
}
