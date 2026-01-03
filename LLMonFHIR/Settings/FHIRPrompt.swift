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
    private let storageKey: LocalPreferenceKey<String?>
    /// A human-readable description of the prompt, localized as needed.
    let localizedDescription: String
    /// The default prompt text to be used if no custom prompt is set.
    private let defaultPrompt: String
    
    /// The current prompt, either from UserDefaults or the default, appended with a localized message that adapts to the user's language settings.
    var prompt: String {
        LocalPreferencesStore.standard[storageKey] ?? defaultPrompt
    }
    
    
    /// - Parameters:
    ///   - storageKey: The key used for storing and retrieving the prompt.
    ///   - localizedDescription: A human-readable description of the prompt, localized as needed.
    ///   - defaultPrompt: The default prompt text to be used if no custom prompt is set.
    init(
        storageKey: String,
        localizedDescription: String,
        defaultPrompt: String
    ) {
        self.storageKey = .init(.init(storageKey))
        self.localizedDescription = localizedDescription
        self.defaultPrompt = defaultPrompt
    }
    
    
    /// Saves a new version of the prompt.
    /// - Parameter prompt: The new prompt.
    func save(prompt: String) {
        LocalPreferencesStore.standard[storageKey] = prompt
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
        prompt
            .replacingOccurrences(of: FHIRPrompt.fhirResourcePlaceholder, with: resource)
            .replacingOccurrences(of: FHIRPrompt.localePlaceholder, with: locale)
    }
}
