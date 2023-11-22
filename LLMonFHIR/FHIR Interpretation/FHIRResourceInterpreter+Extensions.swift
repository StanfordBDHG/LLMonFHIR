//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR
import SpeziFHIRInterpretation
import SpeziOpenAI


extension FHIRResourceInterpreter {
    func chat(forResource resource: FHIRResource) -> [Chat] {
        var chat = [
            Chat(
                role: .system,
                content: FHIRPrompt.interpretation.prompt(withFHIRResource: resource.jsonDescription)
            )
        ]
        
        if let interpretation = cachedInterpretation(forResource: resource) {
            chat.append(Chat(role: .assistant, content: interpretation))
        }
        
        return chat
    }
}
