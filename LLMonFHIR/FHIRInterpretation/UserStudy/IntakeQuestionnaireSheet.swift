//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import class ModelsR4.QuestionnaireResponse
import SpeziLLM
import SpeziLLMOpenAI
import SpeziQuestionnaire
import SpeziQuestionnaireFHIR
import SpeziViews
import SwiftUI


struct IntakeQuestionnaireSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(LLMRunner.self) private var llmRunner
    
    private let study: Study
    @Binding private var fhirResponse: ModelsR4.QuestionnaireResponse?
    
    @State private var isLoadingQuestionnaire = true
    @State private var questionnaire: SpeziQuestionnaire.Questionnaire?
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        Group {
            if let questionnaire {
                QuestionnaireSheet(questionnaire, completionStepConfig: .disable) { result in
                    switch result {
                    case .completed(let responses):
                        await processQuestionnaireResponses(responses)
                    case .cancelled:
                        dismiss()
                    }
                }
            } else if isLoadingQuestionnaire {
                ProgressView("Loading Questionnaire…")
            } else {
                ContentUnavailableView("Unable to load questionnaire", systemImage: "document.badge.gearshape")
                Button("Dismiss") {
                    dismiss()
                }
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
        .task {
            isLoadingQuestionnaire = true
            defer {
                isLoadingQuestionnaire = false
            }
            do {
                guard let fhir = try study.initialQuestionnaire(from: .main) else {
                    return
                }
                questionnaire = try SpeziQuestionnaire.Questionnaire(fhir)
            } catch {
                questionnaire = nil
                #if DEBUG
                viewState = .error(AnyLocalizedError(error: error))
                #endif
            }
        }
    }
    
    init(study: Study, response: Binding<ModelsR4.QuestionnaireResponse?>) {
        self.study = study
        self._fhirResponse = response
    }
    
    private func processQuestionnaireResponses(_ speziResponses: SpeziQuestionnaire.QuestionnaireResponses) async {
        viewState = .processing
        do {
            let fhirResponse = try ModelsR4.QuestionnaireResponse(speziResponses)
            let summary = try await speziResponses.summarize(using: llmRunner)
            study.interpretMultipleResourcesPrompt = """
                \(study.interpretMultipleResourcesPrompt.promptText)
                
                Initial User Questionnaire Summary:
                \(summary)
                """
            self.fhirResponse = fhirResponse
            dismiss()
        } catch {
            // the view will get dismissed when the user dismisses the alert, via the `onChange(of: viewState)` above.
            viewState = .error(AnyLocalizedError(error: error))
            return
        }
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
