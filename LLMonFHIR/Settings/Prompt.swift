//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation


enum Prompt: String {
    /// The summary prompt
    case summary = "prompt.summary"
    /// The interpretation prompt
    case interpretation = "prompt.interpretation"
    
    case interpret_multiple_resources = "prompt.interpret_multiple_resources"
    
    
    static let promptPlaceholder = "%@"
    
    
    var localizedDescription: String {
        switch self {
        case .summary:
            return String(localized: "SETTINGS_PROMPTS_SUMMARY")
        case .interpretation:
            return String(localized: "SETTINGS_PROMPTS_INTERPRETATION")
        case .interpret_multiple_resources:
            return String(localized: "SETTINGS_PROMPTS_INTERPRETATION_MULTIPLE_RESOURCES")
        }
        
    }
    
    var defaultPrompt: String {
        switch self {
        case .summary:
            return String(localized: "FHIR_RESOURCE_SUMMARY_PROMPT \("%@")")
        case .interpretation:
            return String(localized: "FHIR_RESOURCE_INTERPRETATION_PROMPT \("%@")")
        case .interpret_multiple_resources:
            return String(localized: "FHIR_MULTIPLE_RESOURCE_INTERPRETATION_PROMPT \("%@")")
        }
    }
    
    
    var prompt: String {
        UserDefaults.standard.string(forKey: rawValue) ?? defaultPrompt
    }
    
    func save(prompt: String) {
        UserDefaults.standard.set(prompt, forKey: rawValue)
    }
}
