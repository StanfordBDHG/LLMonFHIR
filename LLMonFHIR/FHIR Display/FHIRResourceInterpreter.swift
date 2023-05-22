//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI
import Spezi
import SpeziLocalStorage
import SpeziOpenAI
import SwiftUI


private enum FHIRResourceInterpreterConstants {
    static let storageKey = "FHIRResourceInterpreter.Cache"
}


class FHIRResourceInterpreter<ComponentStandard: Standard>: DefaultInitializable, Component, ObservableObject, ObservableObjectProvider {
    typealias Interpretations = [VersionedResource.ID: String]
    
    
    @Dependency private var localStorage: LocalStorage
    @Dependency private var openAIComponent = OpenAIComponent()
    
    
    var interpretations: Interpretations = [:] {
        willSet {
            Task { @MainActor in
                objectWillChange.send()
            }
        }
        didSet {
            do {
                try localStorage.store(interpretations, storageKey: FHIRResourceInterpreterConstants.storageKey)
            } catch {
                print(error)
            }
        }
    }
    
    
    required init() {}
    
    
    func configure() {
        guard let cachedInterpretation: Interpretations = try? localStorage.read(storageKey: FHIRResourceInterpreterConstants.storageKey) else {
            return
        }
        
        self.interpretations = cachedInterpretation
    }
    
    
    func interpret(resource: VersionedResource) async throws {
        let chatStreamResults = try await openAIComponent.queryAPI(withChat: [systemPrompt(forResource: resource)])
        
        self.interpretations[resource.id] = ""
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                let previousInterpretation = interpretations[resource.id] ?? ""
                interpretations[resource.id] = previousInterpretation + (choice.delta.content ?? "")
            }
        }
    }
    
    func chat(forResource resource: VersionedResource) -> [Chat] {
        var chat = [systemPrompt(forResource: resource)]
        if let interpretation = interpretations[resource.id] {
            chat.append(Chat(role: .assistant, content: interpretation))
        }
        return chat
    }
    
    private func systemPrompt(forResource resource: VersionedResource) -> Chat {
        Chat(
            role: .system,
            content: String(localized: "FHIR_RESOURCE_INTERPRETATION_PROMPT \(resource.jsonDescription)")
        )
    }
}
