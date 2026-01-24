//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable redundant_string_enum_value

public import CryptoKit
import Foundation


/// Manages a collection of survey tasks and their responses.
public final class Study: Identifiable {
    public enum OpenAIEndpointConfig: Equatable, Sendable {
        /// The study uses the regular OpenAI API to generate chat completions
        case regular
        /// The study uses a firebase function to generate chat completions
        case firebaseFunction(name: String)
    }
    
    /// The survey's unique identifier.
    public let id: String
    /// The survey's title.
    public let title: String
    /// A brief explainer detailing what the survey does.
    public let explainer: String
    /// Passcode "used" to unlock the Settings sheet within the app.
    ///
    /// Set this value to `nil` to disable the lock and always have the settings directly accessible.
    public let settingsUnlockCode: String?
    
    /// The OpenAI API key that should be used when answering this survey.
    public var openAIAPIKey: String
    public let openAIEndpoint: OpenAIEndpointConfig
    
    /// The email address to which the report file should be sent.
    public let reportEmail: String?
    
    /// The public key to use when encrypting a report file.
    ///
    /// `nil` if the files should never be encrypted.
    public var encryptionKey: Curve25519.KeyAgreement.PublicKey?
    
    public let summarizeSingleResourcePrompt: FHIRPrompt
    public let interpretMultipleResourcesPrompt: FHIRPrompt
    
    /// The tasks that make up this survey
    public private(set) var tasks: [SurveyTask]
    
    /// Creates a new survey.
    public init(
        id: String,
        title: String,
        explainer: String,
        settingsUnlockCode: String?,
        openAIAPIKey: String,
        openAIEndpoint: OpenAIEndpointConfig,
        reportEmail: String?,
        encryptionKey: Curve25519.KeyAgreement.PublicKey?,
        summarizeSingleResourcePrompt: FHIRPrompt?,
        interpretMultipleResourcesPrompt: FHIRPrompt?,
        tasks: [SurveyTask]
    ) {
        self.id = id
        self.title = title
        self.explainer = explainer
        self.settingsUnlockCode = settingsUnlockCode
        self.openAIAPIKey = openAIAPIKey
        self.openAIEndpoint = openAIEndpoint
        self.reportEmail = reportEmail
        self.encryptionKey = encryptionKey
        self.summarizeSingleResourcePrompt = summarizeSingleResourcePrompt ?? .summarizeSingleFHIRResourceDefaultPrompt
        self.interpretMultipleResourcesPrompt = interpretMultipleResourcesPrompt ?? .interpretMultipleResourcesDefaultPrompt
        self.tasks = tasks
    }
}


extension Study: Hashable {
    public static func == (lhs: Study, rhs: Study) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}


extension Study {
    /// Submits an answer for a specific question in a specific task
    /// - Parameters:
    ///   - answer: The answer to submit
    ///   - taskId: The ID of the task containing the question
    ///   - questionIndex: The index of the question within the task
    /// - Throws: `SurveyError` if the task or question cannot be found or the answer is invalid
    public func submitAnswer(_ answer: TaskQuestionAnswer, forTaskId taskId: SurveyTask.ID, questionIndex: Int) throws {
        guard let groupIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
            throw SurveyError.taskNotFound
        }
        try tasks[groupIndex].updateAnswer(answer, forQuestionIndex: questionIndex)
    }

    /// Resets all answers in the survey to unanswered
    public func resetAllAnswers() {
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
        case settingsUnlockCode = "settings_code"
        case openAIAPIKey = "openai_api_key"
        case openAIEndpoint = "openai_endpoint"
        case reportEmail = "report_email"
        case encryptionKey = "encryption_key"
        case summarizeSingleResourcePrompt = "prompt_summarize_single_resource"
        case interpretMultipleResourcesPrompt = "prompt_interpret_multiple_resources"
    }
    
    public convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            explainer: try container.decode(String.self, forKey: .explainer),
            settingsUnlockCode: try container.decodeIfPresent(String.self, forKey: .settingsUnlockCode),
            openAIAPIKey: try container.decode(String.self, forKey: .openAIAPIKey),
            openAIEndpoint: try container.decode(OpenAIEndpointConfig.self, forKey: .openAIEndpoint),
            reportEmail: try container.decodeIfPresent(String.self, forKey: .reportEmail),
            encryptionKey: try container.decodeIfPresent(Data.self, forKey: .encryptionKey)
                .flatMap { $0.isEmpty ? nil : try .init(pemFileContents: $0) },
            summarizeSingleResourcePrompt: try container.decodeIfPresent(String.self, forKey: .summarizeSingleResourcePrompt)
                .flatMap { $0.isEmpty ? nil : FHIRPrompt(promptText: $0) },
            interpretMultipleResourcesPrompt: try container.decodeIfPresent(String.self, forKey: .interpretMultipleResourcesPrompt)
                .flatMap { $0.isEmpty ? nil : FHIRPrompt(promptText: $0) },
            tasks: try container.decode([SurveyTask].self, forKey: .tasks)
        )
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(explainer, forKey: .explainer)
        try container.encodeIfPresent(settingsUnlockCode, forKey: .settingsUnlockCode)
        try container.encode(openAIAPIKey, forKey: .openAIAPIKey)
        try container.encode(openAIEndpoint, forKey: .openAIEndpoint)
        try container.encodeIfPresent(reportEmail, forKey: .reportEmail)
        try container.encodeIfPresent(encryptionKey?.pemFileContents, forKey: .encryptionKey)
        if summarizeSingleResourcePrompt != .summarizeSingleFHIRResourceDefaultPrompt {
            try container.encode(summarizeSingleResourcePrompt.promptText, forKey: .summarizeSingleResourcePrompt)
        } else {
            try container.encode("", forKey: .summarizeSingleResourcePrompt)
        }
        if interpretMultipleResourcesPrompt != .interpretMultipleResourcesDefaultPrompt {
            try container.encode(interpretMultipleResourcesPrompt.promptText, forKey: .interpretMultipleResourcesPrompt)
        } else {
            try container.encode("", forKey: .interpretMultipleResourcesPrompt)
        }
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
    
    public init(from decoder: any Decoder) throws {
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
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .id)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(assistantMessagesLimit?.llmOnFhirStringValue, forKey: .assistantMessagesLimit)
        try container.encode(questions, forKey: .questions)
    }
}


extension Study.OpenAIEndpointConfig: RawRepresentable, Codable {
    public var rawValue: String {
        switch self {
        case .regular:
            "regular"
        case .firebaseFunction(let name):
            "firebase-function:\(name)"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "regular":
            self = .regular
        case let value where value.starts(with: "firebase-function:"):
            let idx = value.firstIndex(of: ":")! // swiftlint:disable:this force_unwrapping
            let name = String(value[value.index(after: idx)...])
            self = .firebaseFunction(name: name)
        default:
            return nil
        }
    }
}
