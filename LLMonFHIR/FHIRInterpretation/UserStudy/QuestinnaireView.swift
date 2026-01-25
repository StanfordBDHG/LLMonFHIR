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


struct QuestinnaireView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(LLMOpenAIPlatform.self) private var platform
    
    let study: Study
    
    @State private var viewState: ViewState = .idle
    @Binding private(set) var questinnaireResponse: QuestionnaireResponse?
    
    
    var body: some View {
        Group {
            if let initialQuestinnaire = study.initialQuestinnaire {
                if viewState == .idle {
                    QuestionnaireView(
                        questionnaire: initialQuestinnaire,
                        questionnaireResult: { result in
                            switch result {
                            case let .completed(questinnaireResponse):
                                self.questinnaireResponse = questinnaireResponse
                            default:
                                break
                            }
                        }
                    )
                } else {
                    progressView
                }
            } else {
                ContentUnavailableView("Questinnaire not selected", systemImage: "document.badge.gearshape")
            }
        }
        .onChange(of: questinnaireResponse) {
            processQuestinnaireResponse()
        }
        .viewStateAlert(state: $viewState)
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
    
    
    private func processQuestinnaireResponse() {
        guard let questinnaireResponse, let initialQuestinnaire = study.initialQuestinnaire else {
            dismiss()
            return
        }
        
        viewState = .processing
        
        Task { // swiftlint:disable:this closure_body_length
            do {
                let session = platform(
                    with: LLMOpenAISchema(
                        parameters: LLMOpenAIParameters(
                            modelType: .gpt5_mini,
                            systemPrompt: """
                            Your task is to transform the FHIR questinnaire response into text, do not leave out any question or response.
                            List all questions and their written out answers next to each other. Do not list the code or coding system.
                            Questinnaire:
                            ```json
                            \((try? String(data: JSONEncoder().encode(initialQuestinnaire), encoding: .utf8)) ?? "")
                            ```
                            Questinnaire Response:
                            ```json
                            \((try? String(data: JSONEncoder().encode(questinnaireResponse), encoding: .utf8)) ?? "")
                            ```
                            """
                        )
                    )
                )
                var questinnaireSummary = ""
                for try await token in try await session.generate() {
                    questinnaireSummary.append(token)
                }
                
                study.interpretMultipleResourcesPrompt = FHIRPrompt(
                    promptText: """
                    \(study.interpretMultipleResourcesPrompt.promptText)
                    
                    Initial User Questinnaire Summary:
                    \(questinnaireSummary)
                    """
                )
                
                dismiss()
            } catch {
                viewState = .error(AnyLocalizedError(error: error))
            }
        }
    }
}
