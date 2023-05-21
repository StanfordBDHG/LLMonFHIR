//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR


/// The context attached to each task in the Spezi LLMonFHIR.
///
/// We currently only support `Questionnaire`s, more cases can be added in the future.
enum LLMonFHIRTaskContext: Codable, Identifiable {
    /// The task schould display a `Questionnaire`.
    case questionnaire(Questionnaire)
    
    
    var id: Questionnaire.ID {
        switch self {
        case let .questionnaire(questionnaire):
            return questionnaire.id
        }
    }
    
    var actionType: String {
        switch self {
        case .questionnaire:
            return String(localized: "TASK_CONTEXT_ACTION_QUESTIONNAIRE")
        }
    }
}
