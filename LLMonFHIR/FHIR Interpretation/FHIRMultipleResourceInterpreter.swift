//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import Spezi
import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziLocalStorage
import SpeziOpenAI
import SwiftUI


private enum FHIRMultipleResourceInterpreterConstants {
    static let storageKey = "FHIRMultipleResourceInterpreter.Cache"
}


@Observable
class FHIRMultipleResourceInterpreter {
    private let localStorage: LocalStorage
    private let openAIModel: OpenAIModel
    private let fhirStore: FHIRStore
    
    
    var interpretation: String? {
        didSet {
            do {
                try localStorage.store(interpretation, storageKey: FHIRMultipleResourceInterpreterConstants.storageKey)
            } catch {
                print(error)
            }
        }
    }
    
    
    required init(localStorage: LocalStorage, openAIModel: OpenAIModel, fhirStore: FHIRStore) {
        self.localStorage = localStorage
        self.openAIModel = openAIModel
        self.fhirStore = fhirStore
    }
    
    
    func configure() {
        guard let cachedInterpretation: String = try? localStorage.read(
            storageKey: FHIRMultipleResourceInterpreterConstants.storageKey
        ) else {
            return
        }
        self.interpretation = cachedInterpretation
    }
    
    func interpretMultipleResources(resources: [FHIRResource]) async throws {
        guard interpretation == nil else {
            return
        }
        
        let chatStreamResults = try await openAIModel.queryAPI(withChat: [systemPrompt(forResources: resources)])
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                interpretation = (interpretation ?? "") + (choice.delta.content ?? "")
            }
        }
    }
    
    func chat(resources: [FHIRResource]) -> [Chat] {
        var chat = [systemPrompt(forResources: resources)]
        
        if let interpretation = interpretation {
            chat.append(Chat(role: .assistant, content: interpretation))
        }
        
        return chat
    }

    
    private func systemPrompt(forResources resources: [FHIRResource]) -> Chat {
        var resourceCategories = String()
        
        for resource in resources {
            resourceCategories += (resource.functionCallIdentifier + "\n")
        }
        
        return Chat(
            role: .system,
            content: FHIRPrompt.interpretMultipleResources.prompt(withFHIRResource: resourceCategories)
        )
    }
}


extension FHIRPrompt {
    /// Prompt used to interpret multple FHIR resources
    ///
    /// This prompt is used by the ``FHIRMultipleResourceInterpreter``.
    public static let interpretMultipleResources: FHIRPrompt = {
        FHIRPrompt(
            storageKey: "prompt.interpretMultipleResources",
            localizedDescription: String(
                localized: "Interpretation Prompt",
                comment: "Title of the multiple resources interpretation prompt."
            ),
            defaultPrompt: String(
                localized: "Interpretation Prompt Content",
                comment: "Content of the multiple resources interpretation prompt."
            )
        )
    }()
}
