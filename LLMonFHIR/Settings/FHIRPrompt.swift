//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFoundation


/// Handle dynamic, localized LLM prompts for FHIR resources.
struct FHIRPrompt: Hashable, Sendable {
    /// Placeholder for FHIR resource in prompts.
    static let fhirResourcePlaceholder = "{{FHIR_RESOURCE}}"
    /// Placeholder for the current locale in a prompt
    static let localePlaceholder = "{{LOCALE}}"
    
    /// The key used for storing and retrieving the prompt.
    private let storageKey: LocalPreferenceKey<String?>?
    /// A human-readable description of the prompt, localized as needed.
    let localizedDescription: String
    /// The default prompt text to be used if no custom prompt is set.
    private let defaultPromptText: String
    
    /// The current prompt, either from UserDefaults or the default, appended with a localized message that adapts to the user's language settings.
    var promptText: String {
        storageKey.flatMap { LocalPreferencesStore.standard[$0] } ?? defaultPromptText
    }
    
    /// Whether the `FHIRPrompt` supports being customised by the user.
    var isCustomizable: Bool {
        storageKey != nil
    }
    
    /// - Parameters:
    ///   - storageKey: The key used for storing and retrieving the prompt.
    ///   - localizedDescription: A human-readable description of the prompt, localized as needed.
    ///   - defaultPrompt: The default prompt text to be used if no custom prompt is set.
    init(
        storageKey: String,
        localizedDescription: String,
        defaultPromptText: String
    ) {
        self.storageKey = .init(.init(storageKey))
        self.localizedDescription = localizedDescription
        self.defaultPromptText = defaultPromptText
    }
    
    init(promptText: String) {
        self.storageKey = nil
        self.localizedDescription = ""
        self.defaultPromptText = promptText
    }
    
    
    /// Saves a new version of the prompt, if the prompt definition is persistable to UserDefaults.
    /// - Parameter prompt: The new prompt.
    func save(prompt: String) {
        if let storageKey {
            LocalPreferencesStore.standard[storageKey] = prompt
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(storageKey)
    }
    
    /// Creates a prompt based in the variable input.
    ///
    /// Use ``FHIRPrompt/fhirResourcePlaceholder`` and ``FHIRPrompt/localePlaceholder`` to define the elements that should be replaced.
    /// - Parameters:
    ///   - resource: The resource that should be inserted in the prompt.
    ///   - locale: The current locale that should be inserted in the prompt.
    /// - Returns: The constructed prompt.
    func prompt(withFHIRResource resource: String, locale: String = Locale.preferredLanguages[0]) -> String {
        promptText
            .replacingOccurrences(of: FHIRPrompt.fhirResourcePlaceholder, with: resource)
            .replacingOccurrences(of: FHIRPrompt.localePlaceholder, with: locale)
    }
}


extension FHIRPrompt {
    /// Prompt used to interpret multiple FHIR resources
    ///
    /// This prompt is used by the ``FHIRMultipleResourceInterpreter``.
    static let interpretMultipleResourcesDefaultPrompt = FHIRPrompt(
        storageKey: "prompt.interpretMultipleResources",
        localizedDescription: String(
            localized: "Interpretation Prompt",
            bundle: .main,
            comment: "Title of the multiple resources interpretation prompt."
        ),
        defaultPromptText: String(
            localized: "Multiple Resource Interpretation Prompt Content",
            bundle: .main,
            comment: "Content of the multiple resources interpretation prompt."
        )
    )
    
    
    /// Prompt used to summarize FHIR resources
    ///
    /// This prompt is used by the ``FHIRResourceSummary``.
    static let summarizeSingleFHIRResourceDefaultPrompt = FHIRPrompt(
        storageKey: "prompt.summary",
        localizedDescription: String(
            localized: "SUMMARY_PROMPT",
            bundle: .main
        ),
        defaultPromptText: String(
            localized: "SUMMARY_PROMPT_CONTENT_OPENAI",
            bundle: .main
        )
    )
    
    
    /// Prompt used to interpret FHIR resources
    ///
    /// This prompt is used by the ``FHIRResourceInterpreter``.
    static let interpretSingleFHIRResource = FHIRPrompt(
        storageKey: "prompt.interpretation",
        localizedDescription: String(
            localized: "Interpretation Prompt",
            bundle: .main,
            comment: "Title of the interpretation prompt."
        ),
        defaultPromptText: String(
            localized: "Interpretation Prompt Content",
            bundle: .main,
            comment: "Content of the interpretation prompt."
        )
    )
}
