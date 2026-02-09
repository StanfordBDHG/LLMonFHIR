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
import class ModelsR4.Patient
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
    
    /// The raw name of the `bundle`, as specified in the config file.
    let bundleInputName: String
    
    /// The FHIR bundle providing the resources that will be made available to the LLM
    ///
    /// - Note: Isn't allowed to be mutated
    nonisolated(unsafe) let bundle: ModelsR4.Bundle
    
    /// The OpenAI API key used when simulating this session.
    let openAIKey: String
    
    /// The questions that should be asked by the simulated patient.
    let userQuestions: [String]
}


extension SimulatedSessionConfig: Decodable {
    private enum CodingKeys: String, CodingKey {
        case numberOfRuns
        case studyId
        case bundleName
        case openAIKey
        case userQuestions
        case model
        case temperature
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.numberOfRuns = try container.decode(Int.self, forKey: .numberOfRuns)
        self.temperature = try container.decode(Double.self, forKey: .temperature)
        self.openAIKey = try container.decode(String.self, forKey: .openAIKey)
        let studyId = try container.decode(Study.ID.self, forKey: .studyId)
        guard let study = Study.allStudies.first(where: { $0.id == studyId }) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to find study with id '\(studyId)'"))
        }
        self.study = study
        bundleInputName = try container.decode(String.self, forKey: .bundleName)
        guard let bundle = ModelsR4.Bundle.named(bundleInputName) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to find bundle named '\(bundleInputName)'"))
        }
        self.bundle = bundle
        self.userQuestions = try container.decode([String].self, forKey: .userQuestions)
        self.model = try container.decode(LLMOpenAIParameters.ModelType.self, forKey: .model)
    }
}
