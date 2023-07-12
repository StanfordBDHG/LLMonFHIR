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


private enum FHIRMultipleResourceInterpreterConstants {
    static let storageKey = "FHIRMultipleResourceInterpreter.Cache"
}


class FHIRMultipleResourceInterpreter<ComponentStandard: Standard>: DefaultInitializable, Component, ObservableObject, ObservableObjectProvider {
    typealias MultipleResourceInterpretation = String
    @Dependency private var localStorage: LocalStorage
    @Dependency private var openAIComponent = OpenAIComponent()
    
    var interpretation: String? {
        willSet {
            Task { @MainActor in
                objectWillChange.send()
            }
        }
        didSet {
            do {
                try localStorage.store(interpretation, storageKey: FHIRMultipleResourceInterpreterConstants.storageKey)
            } catch {
                print(error)
            }
        }
    }
    
    
    required init() {}
    
    
    func configure() {
        guard let cachedInterpretation: MultipleResourceInterpretation = try? localStorage.read(
            storageKey: FHIRMultipleResourceInterpreterConstants.storageKey
        ) else {
            return
        }
        self.interpretation = cachedInterpretation
    }
    
    func interpretMultipleResources(resources: [FHIRResource]) async throws {
        let chatStreamResults = try await openAIComponent.queryAPI(withChat: [systemPrompt(forResources: resources)])
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                let previousInterpretation = interpretation ?? ""
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
        var allJSONResources = ""
        
        for resource in resources {
            allJSONResources = allJSONResources + "\n" + resource.compactJSONDescription
        }

        return Chat(
            role: .system,
            content: Prompt.interpretMultipleResources.prompt.replacingOccurrences(of: Prompt.promptPlaceholder, with: allJSONResources)
        )
    }
}
