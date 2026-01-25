//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import Foundation
private import SpeziFoundation


/// Handle dynamic, localized LLM prompts for FHIR resources.
public struct FHIRPrompt: Hashable, Sendable {
    /// Placeholder for FHIR resource in prompts.
    public static let fhirResourcePlaceholder = "{{FHIR_RESOURCE}}"
    /// Placeholder for the current locale in a prompt
    public static let localePlaceholder = "{{LOCALE}}"
    
    /// The key used for storing and retrieving the prompt.
    private let storageKey: LocalPreferenceKey<String?>?
    
    /// The default prompt text to be used if no custom prompt is set.
    private let defaultPromptText: String
    
    /// The current prompt, either from UserDefaults or the default, appended with a localized message that adapts to the user's language settings.
    public var promptText: String {
        storageKey.flatMap { LocalPreferencesStore.standard[$0] } ?? defaultPromptText
    }
    
    /// Whether the `FHIRPrompt` supports being customised by the user.
    public var isCustomizable: Bool {
        storageKey != nil
    }
    
    /// - Parameters:
    ///   - storageKey: The key used for storing and retrieving the prompt.
    ///   - defaultPrompt: The default prompt text to be used if no custom prompt is set.
    public init(
        storageKey: String,
        defaultPromptText: String
    ) {
        self.storageKey = .init(.init(storageKey))
        self.defaultPromptText = defaultPromptText
    }
    
    public init(promptText: String) {
        self.storageKey = nil
        self.defaultPromptText = promptText
    }
    
    
    /// Saves a new version of the prompt, if the prompt definition is persistable to UserDefaults.
    /// - Parameter prompt: The new prompt.
    public func save(prompt: String) {
        if let storageKey {
            LocalPreferencesStore.standard[storageKey] = prompt
        }
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
        promptText
            .replacingOccurrences(of: FHIRPrompt.fhirResourcePlaceholder, with: resource)
            .replacingOccurrences(of: FHIRPrompt.localePlaceholder, with: locale)
    }
}


extension FHIRPrompt: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(promptText: value)
    }
}
