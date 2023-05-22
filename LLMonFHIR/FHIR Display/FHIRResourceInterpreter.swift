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
    static let cacheKey = "FHIRResourceInterpreter.Cache"
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
                try localStorage.store(interpretations, storageKey: FHIRResourceInterpreterConstants.cacheKey)
            } catch {
                print(error)
            }
        }
    }
    
    
    required init() {}
    
    
    func configure() {
        guard let cachedInterpretation: Interpretations = try? localStorage.read(storageKey: FHIRResourceInterpreterConstants.cacheKey) else {
            return
        }
        
        self.interpretations = cachedInterpretation
    }
    
    
    func interpret(resource: VersionedResource) async throws {
        let chatStreamResults = try await openAIComponent.queryAPI(
            withChat: [
                Chat(
                    role: .system,
                    content: """
                    You are the "LLM on FHIR" applicatation.
                    Your task is to interpret the following FHIR resource from the user's clinical record.
                    
                    Interpret the resource by explaining its data relevant to the user's health.
                    Explain the relevant medical context in a language understandable by a user who is not a medical professional.
                    You should provide factual and precise information in a compact summary in short responses.
                    
                    The following JSON representation defines the FHIR resource that you should interpret:
                    \(resource.jsonDescription)
                    
                    Immediately return an interpretation to the user, starting the conversation.
                    Do not introduce yourself at the beginning and start with your interpretation.
                    """
                )
            ]
        )
        
        self.interpretations[resource.id] = ""
        
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                let previousInterpretation = interpretations[resource.id] ?? ""
                interpretations[resource.id] = previousInterpretation + (choice.delta.content ?? "")
            }
        }
    }
}
