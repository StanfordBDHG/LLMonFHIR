//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LLMonFHIRShared
import LLMonFHIRStudyDefinitions
import class ModelsR4.Bundle
import SpeziLLMOpenAI


struct SimulatedSessionConfig: Sendable {
    let numberOfRuns: Int
    let model: LLMOpenAIParameters.ModelType
    let temperature: Double
    
    /// The study that should be simulated.
    ///
    /// Only the study's prompts are actually used for the simulation; any additional components (eg an initial questionnaire, or instructions/tasks) are ignored.
    ///
    /// - Note: Isn't allowed to be mutated
    nonisolated(unsafe) let study: Study
    
    /// The raw input based on which the ``bundle`` was loaded, as specified in the config file.
    let bundleInputName: String
    
    /// The FHIR bundle providing the resources that will be made available to the LLM
    ///
    /// - Note: Isn't allowed to be mutated
    nonisolated(unsafe) let bundle: ModelsR4.Bundle
    
    /// The service that should be used for the simulation.
    let service: Service

    /// Optional human-readable name for this config, used as the output filename prefix.
    let name: String?

    /// Optional text appended to the study's default system prompt.
    let systemPromptSuffix: String?

    /// The questions that should be asked by the simulated patient.
    let userQuestions: [String]

    /// The effective system prompt: the study's default prompt with any suffix appended.
    var systemPrompt: FHIRPrompt {
        guard let suffix = systemPromptSuffix, !suffix.isEmpty else {
            return study.interpretMultipleResourcesPrompt
        }
        return FHIRPrompt(
            promptText: study.interpretMultipleResourcesPrompt.promptText + "\n\n" + suffix
        )
    }
}

extension SimulatedSessionConfig: DecodableWithConfiguration {
    enum Service: String, Codable {
        case openAI = "OpenAI"
        case firebase = "Firebase"
        case firebaseEmulator = "Firebase-Emulator"
    }

    struct DecodingConfiguration {
        /// The URL of the config file being decoded, if applicable.
        let configFileUrl: URL?
    }
    
    private enum CodingKeys: String, CodingKey {
        case numberOfRuns
        case name
        case studyId
        case bundleName
        case service
        case systemPromptSuffix
        case userQuestions
        case model
        case temperature
    }
    
    init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.numberOfRuns = try container.decode(Int.self, forKey: .numberOfRuns)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.model = try container.decode(LLMOpenAIParameters.ModelType.self, forKey: .model)
        self.temperature = try container.decode(Double.self, forKey: .temperature)
        self.service = try Self.inferService(from: container)

        let studyId = try container.decode(Study.ID.self, forKey: .studyId)
        guard let study = Study.allStudies.first(where: { $0.id == studyId }) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to find study with id '\(studyId)'"))
        }
        self.study = study
        bundleInputName = try container.decode(String.self, forKey: .bundleName)
        let url = URL(filePath: bundleInputName, relativeTo: configuration.configFileUrl?.deletingLastPathComponent())
        if FileManager.default.itemExists(at: url) && !FileManager.default.isDirectory(at: url) {
            bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
        } else {
            guard let bundle = ModelsR4.Bundle.forPatient(named: bundleInputName) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to find bundle named '\(bundleInputName)'"))
            }
            self.bundle = bundle
        }
        self.systemPromptSuffix = try container.decodeIfPresent(
            String.self,
            forKey: .systemPromptSuffix
        )
        self.userQuestions = try container.decode([String].self, forKey: .userQuestions)
    }

    private static func inferService(from container: KeyedDecodingContainer<CodingKeys>) throws -> Service {
        if let service = try container.decodeIfPresent(Service.self, forKey: .service) {
            return service
        }
        let env = ProcessInfo.processInfo.environment
        if let apiKey = env["OPENAI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !apiKey.isEmpty {
            print("No 'service' specified — inferring 'OpenAI' from OPENAI_API_KEY environment variable.")
            return .openAI
        } else if let plist = env["GOOGLE_CREDENTIALS_PLIST"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !plist.isEmpty {
            print("No 'service' specified — inferring 'Firebase' from GOOGLE_CREDENTIALS_PLIST environment variable.")
            return .firebase
        } else {
            print("No 'service' specified and no credentials found in environment — defaulting to 'Firebase-Emulator'.")
            return .firebaseEmulator
        }
    }
}
