//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

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
    
    // we're not collecting any survey responses in the simulated sessions, so this is in fact safe.
    nonisolated(unsafe) let study: Study
    // isn't allowed to get mutated.
    nonisolated(unsafe) let bundle: ModelsR4.Bundle
    let openAIKey: String
    
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
        let bundleName = try container.decode(String.self, forKey: .bundleName)
        guard let bundle = ModelsR4.Bundle.named(bundleName) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to find bundle named '\(bundleName)'"))
        }
        self.bundle = bundle
        self.userQuestions = try container.decode([String].self, forKey: .userQuestions)
        self.model = try container.decode(LLMOpenAIParameters.ModelType.self, forKey: .model)
    }
    
//    func encode(to encoder: any Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(study.id, forKey: .studyId)
//        
//        fatalError()
//    }
}


extension ModelsR4.Bundle {
    static func named(_ bundleName: String) -> ModelsR4.Bundle? {
        allCustomBundles()[bundleName]
    }
    
    static func allCustomBundles() -> [String: ModelsR4.Bundle] {
        guard let synthPatientsUrl = Foundation.Bundle.llmOnFhirShared.url(forResource: "Synthetic Patients", withExtension: nil),
              let enumerator = FileManager.default.enumerator(
                at: synthPatientsUrl,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else {
            return [:]
        }
        var bundlesByPatientName: [String: ModelsR4.Bundle] = [:]
        for url in enumerator.lazy.compactMap({ $0 as? URL }) {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else {
                continue
            }
            let bundle: ModelsR4.Bundle
            do {
                bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(contentsOf: url))
            } catch {
                print("Skipping \(url.path): \(error)")
                continue
            }
            guard let patientName = bundle.singlePatient?.fullName else {
                print("no patient / name")
                continue
            }
            bundlesByPatientName[patientName] = bundle
        }
        return bundlesByPatientName
    }
}


extension ModelsR4.Bundle {
    var singlePatient: ModelsR4.Patient? {
        guard let patients = entry?.compactMap({ $0.resource?.get(if: ModelsR4.Patient.self) }), patients.count == 1 else {
            return nil
        }
        return patients.first
    }
}


extension ModelsR4.Patient {
    var fullName: String? {
        for name in name ?? [] {
            let familyName = name.family?.value?.string ?? ""
            let givenNames = (name.given?.compactMap { $0.value?.string } ?? []).filter { !$0.isEmpty }
            switch (givenNames.isEmpty, familyName.isEmpty) {
            case (true, true): // we have nothing
                continue
            case (true, false): // we have given names, but no family name
                return givenNames.joined(separator: " ")
            case (false, true): // family name yes given names no
                return familyName
            case (false, false):
                return "\(givenNames.joined(separator: " ")) \(familyName)"
            }
        }
        return nil
    }
}
