//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import class ModelsR4.QuestionnaireResponse
import SpeziLLMOpenAI
import SpeziQuestionnaire
import SpeziViews
import SwiftUI


struct QuestionnaireSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let study: Study
    @Binding var response: QuestionnaireResponse?
    @State private var viewState: ViewState = .idle
    
    
    var body: some View {
        Group {
            if let questionnaire = try? study.initialQuestionnaire(from: .main) {
                QuestionnaireView(questionnaire: questionnaire) { result in
                    switch result {
                    case .completed(let response):
                        self.response = response
                        await processQuestionnaireResponse()
                    case .cancelled:
                        dismiss()
                    case .failed(let error):
                        viewState = .error(AnyLocalizedError(error: error))
                    }
                }
            } else {
                ContentUnavailableView("Questionnaire not selected", systemImage: "document.badge.gearshape")
            }
        }
        .viewStateAlert(state: $viewState)
        .onChange(of: viewState) { oldValue, newValue in
            if oldValue.isError && newValue == .idle {
                // we were displaying an error but it got dismissed and we're now back in the idle state.
                // in this case we simply want to dismiss the view
                dismiss()
            }
        }
    }
    
    private func processQuestionnaireResponse() async {
        guard let response, let questionnaire = try? study.initialQuestionnaire(from: .main) else {
            dismiss()
            return
        }
        
        viewState = .processing
        
        let summary = response.summary(basedOn: questionnaire)
        study.interpretMultipleResourcesPrompt = """
            \(study.interpretMultipleResourcesPrompt.promptText)
            
            Initial User Questionnaire Summary:
            \(summary)
            """
        
        dismiss()
    }
}


extension ViewState {
    var isError: Bool {
        switch self {
        case .error:
            true
        case .idle, .processing:
            false
        }
    }
}
