//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


/// Handle dynamic, localized LLM prompts for FHIR resources.
public struct FHIRPrompt: Hashable, Sendable {
    /// Placeholder for FHIR resource in prompts.
    public static let fhirResourcePlaceholder = "{{FHIR_RESOURCE}}"
    /// Placeholder for the current locale in a prompt
    public static let localePlaceholder = "{{LOCALE}}"
    
    /// The key used for storing and retrieving the prompt.
    public let storageKey: String
    /// A human-readable description of the prompt, localized as needed.
    public let localizedDescription: String
    /// The default prompt text to be used if no custom prompt is set.
    public let defaultPrompt: String
    
    /// The current prompt, either from UserDefaults or the default, appended with a localized message that adapts to the user's language settings.
    public var prompt: String {
        UserDefaults.standard.string(forKey: storageKey) ?? defaultPrompt
    }
    
    
    /// - Parameters:
    ///   - storageKey: The key used for storing and retrieving the prompt.
    ///   - localizedDescription: A human-readable description of the prompt, localized as needed.
    ///   - defaultPrompt: The default prompt text to be used if no custom prompt is set.
    public init(
        storageKey: String,
        localizedDescription: String,
        defaultPrompt: String
    ) {
        self.storageKey = storageKey
        self.localizedDescription = localizedDescription
        self.defaultPrompt = defaultPrompt
    }
    
    
    /// Saves a new version of the prompt.
    /// - Parameter prompt: The new prompt.
    public func save(prompt: String) {
        UserDefaults.standard.set(prompt, forKey: storageKey)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storageKey)
    }
    
    /// Creates a prompt based in the variable input.
    ///
    /// Use ``FHIRPrompt/fhirResourcePlaceholder`` and ``FHIRPrompt/localePlaceholder`` to define the elements that should be replaced.
    /// - Parameters:
    ///   - resource: The resource that should be inserted in the prompt.
    ///   - locale: The current locale that should be inserted in the prompt.
    /// - Returns: The constructed prompt.
    public func prompt(withFHIRResource resource: String, locale: String = Locale.preferredLanguages[0]) -> String {
        prompt
            .replacingOccurrences(of: FHIRPrompt.fhirResourcePlaceholder, with: resource)
            .replacingOccurrences(of: FHIRPrompt.localePlaceholder, with: locale)
    }
}
