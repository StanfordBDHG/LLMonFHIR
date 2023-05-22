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


private enum FHIRResourceSummaryConstants {
    static let storageKey = "FHIRResourceSummary.Cache.Descriptions"
}


class FHIRResourceSummary<ComponentStandard: Standard>: DefaultInitializable, Component, ObservableObject, ObservableObjectProvider {
    typealias Summaries = [VersionedResource.ID: FHIRResourceSummary]
    
    
    struct FHIRResourceSummary: LosslessStringConvertible, Codable {
        init?(_ description: String) {
            let lines = description.split(whereSeparator: \.isNewline)
            
            guard lines.count == 2, let title = lines.first, let summary = lines.last else {
                return nil
            }
            
            self.title = String(title)
            self.summary = String(summary)
        }
        
        init(title: String, summary: String) {
            self.title = title
            self.summary = summary
        }
        
        
        let title: String
        let summary: String
        
        
        var description: String {
            "\(title)\n\(summary)"
        }
    }
    
    
    @Dependency private var localStorage: LocalStorage
    @Dependency private var openAIComponent = OpenAIComponent()
    
    
    var summaries: Summaries = [:] {
        willSet {
            Task { @MainActor in
                objectWillChange.send()
            }
        }
        didSet {
            do {
                try localStorage.store(summaries, storageKey: FHIRResourceSummaryConstants.storageKey)
            } catch {
                print(error)
            }
        }
    }
    
    
    required init() {}
    
    
    func configure() {
        guard let cachedSummaries: Summaries = try? localStorage.read(storageKey: FHIRResourceSummaryConstants.storageKey) else {
            return
        }
        
        self.summaries = cachedSummaries
    }
    
    
    func summarize(resource: VersionedResource) async throws {
        guard summaries[resource.id] == nil else {
            return
        }
        
        
        let chatStreamResults = try await openAIComponent.queryAPI(withChat: [systemPrompt(forResource: resource)])
        
        var summaryString = ""
        for try await chatStreamResult in chatStreamResults {
            for choice in chatStreamResult.choices {
                summaryString.append(choice.delta.content ?? "")
            }
        }
        
        self.summaries[resource.id] = FHIRResourceSummary(summaryString)
    }
    
    
    private func systemPrompt(forResource resource: VersionedResource) -> Chat {
        Chat(
            role: .system,
            content: String(localized: "FHIR_RESOURCE_SUMMARY_PROMPT \(resource.jsonDescription)")
        )
    }
}
