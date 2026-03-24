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
import SpeziLLMOpenAI

import class ModelsR4.Bundle

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

    let service: Service

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
            promptText: study.interpretMultipleResourcesPrompt.promptText + "\n\n" + suffix)
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
        self.model = try container.decode(LLMOpenAIParameters.ModelType.self, forKey: .model)
        self.temperature = try container.decode(Double.self, forKey: .temperature)

        if let decodedService = try container.decodeIfPresent(Service.self, forKey: .service) {
            self.service = decodedService
        } else {
            let env = ProcessInfo.processInfo.environment
            if env["OPENAI_API_KEY"] != nil {
                print("No 'service' specified — inferring 'OpenAI' from OPENAI_API_KEY environment variable.")
                self.service = .openAI
            } else if env["GOOGLE_CREDENTIALS_PLIST"] != nil {
                print("No 'service' specified — inferring 'Firebase' from GOOGLE_CREDENTIALS_PLIST environment variable.")
                self.service = .firebase
            } else {
                print("No 'service' specified and no credentials found in environment — defaulting to 'Firebase-Emulator'.")
                self.service = .firebaseEmulator
            }
        }

        let studyId = try container.decode(Study.ID.self, forKey: .studyId)
        guard let study = Study.allStudies.first(where: { $0.id == studyId }) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Unable to find study with id '\(studyId)'")
            )
        }
        self.study = study
        bundleInputName = try container.decode(String.self, forKey: .bundleName)
        let url = URL(
            filePath: bundleInputName,
            relativeTo: configuration.configFileUrl?.deletingLastPathComponent())
        if FileManager.default.itemExists(at: url) && !FileManager.default.isDirectory(at: url) {
            do {
                bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
            } catch {
                print("Bundle decoding failed for file: \(url): \(error)")
                throw error
            }
        } else {
            guard let bundle = ModelsR4.Bundle.forPatient(named: bundleInputName) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription: "Unable to find bundle named '\(bundleInputName)'"))
            }
            self.bundle = bundle
        }
        self.systemPromptSuffix = try container.decodeIfPresent(
            String.self, forKey: .systemPromptSuffix)
        self.userQuestions = try container.decode([String].self, forKey: .userQuestions)
    }
}

extension SimulatedSessionConfig.Service {
    var reportService: StudyReport.Metadata.LLMConfig.Service {
        switch self {
        case .openAI: .openAI
        case .firebase: .firebase
        case .firebaseEmulator: .firebaseEmulator
        }
    }
}
