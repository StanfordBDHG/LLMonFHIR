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
    @Environment(LLMOpenAIPlatform.self) private var platform
    
    let study: Study
    @Binding var response: QuestionnaireResponse?
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        Group {
            if let questionnaire = study.initialQuestionnaire {
                questionnaireView(using: questionnaire)
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
    
    @ViewBuilder private var progressView: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                Color.clear.ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(2.0)
                        .tint(.accentColor)
                        .padding(32)
                    Text("Processing Questionnaire Response ...")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    Text("It may take a few moments while we analyze your answers.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton()
                }
            }
        }
    }
    
    private func questionnaireView(using questionnaire: Questionnaire) -> some View {
        ZStack {
            SpeziQuestionnaire.QuestionnaireView(questionnaire: questionnaire) { result in
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
            if viewState == .processing {
                progressView
            }
        }
    }
    
    private func processQuestionnaireResponse() async {
        guard let response, let questionnaire = study.initialQuestionnaire else {
            dismiss()
            return
        }
        viewState = .processing
        do {
            let session = platform(
                with: LLMOpenAISchema(
                    parameters: LLMOpenAIParameters(
                        modelType: .gpt5_mini,
                        systemPrompt: """
                        Your task is to transform a FHIR questionnaire response into text; do not leave out any question or response.
                        List all questions and their written out answers next to each other. Do not list the code or coding system.
                        Questionnaire:
                        ```json
                        \((try? String(data: JSONEncoder().encode(questionnaire), encoding: .utf8)) ?? "")
                        ```
                        Questionnaire Response:
                        ```json
                        \((try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? "")
                        ```
                        """
                    )
                )
            )
            var summary = ""
            for try await token in try await session.generate() {
                summary.append(token)
            }
            study.interpretMultipleResourcesPrompt = """
                \(study.interpretMultipleResourcesPrompt.promptText)
                
                Initial User Questionnaire Summary:
                \(summary)
                """
            dismiss()
        } catch {
            viewState = .error(AnyLocalizedError(error: error))
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
