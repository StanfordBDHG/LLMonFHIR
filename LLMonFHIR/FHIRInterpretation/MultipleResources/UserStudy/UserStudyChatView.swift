//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziFHIR
import SpeziLLM
import SpeziLLMOpenAI
import SpeziSpeechSynthesizer
import SpeziViews
import SwiftUI


// MARK: - View Model

/// Represents the state for a user study chat session
@MainActor
final class UserStudyViewModel: ObservableObject {
    /// The current state of the survey navigation
    enum NavigationState: Equatable {
        case introduction
        case task(number: Int, total: Int)
        case completed

        var title: String {
            switch self {
            case .introduction:
                return "Introduction"
            case let .task(number, total):
                return "Task \(number) of \(total)"
            case .completed:
                return "Study Completed"
            }
        }
    }

    /// The current navigation state of the study
    @Published private(set) var navigationState: NavigationState = .introduction

    /// Indicates whether the survey portion has been started
    @Published private(set) var isSurveyStarted = false

    /// Controls the visibility of the survey view
    @Published var isSurveyViewPresented = false

    /// Controls the visibility of the dismiss confirmation dialog
    @Published var isDismissDialogPresented = false

    private let survey: Survey
    private var currentTaskNumber: Int = 0 {
        didSet {
            updateNavigationState()
        }
    }


    /// Creates a new view model for managing a user study chat session
    /// - Parameter survey: The survey configuration to use for this study
    init(survey: Survey) {
        self.survey = survey
    }


    /// Handles the submission of survey answers for the current task
    /// - Parameter answers: Array of answers provided by the user
    /// - Throws: An error if the submission fails
    func submitSurveyAnswers(_ answers: [Answer]) throws {
        for (index, answer) in answers.enumerated() {
            try survey.submitAnswer(answer, forTaskId: currentTaskNumber, questionIndex: index)
        }

        advanceToNextTask()
    }

    /// Resets the study to its initial state
    func resetStudy() {
        survey.resetAllAnswers()
        currentTaskNumber = 0
        isSurveyStarted = false
        updateNavigationState()
    }

    /// Starts the survey portion of the study
    func startSurvey() {
        if isSurveyStarted {
            return
        }
        isSurveyStarted = true
        currentTaskNumber = 1
    }

    /// Generates a report file for the completed study
    /// - Returns: A shareable file containing the study results
    func generateReportURL() -> URL {
        survey.generateReportFile()
    }

    /// Generates a formatted string for the completed study
    /// - Returns: A formatted string containing the study results
    func generateReport() -> String {
        survey.generateReport()
    }

    /// Returns the current task if one is active
    /// - Returns: The current survey task, if available
    func getCurrentTask() -> SurveyTask? {
        survey.tasks.first { $0.id == currentTaskNumber }
    }

    private func advanceToNextTask() {
        if currentTaskNumber < survey.tasks.count {
            currentTaskNumber += 1
        } else {
            navigationState = .completed
        }
    }

    private func updateNavigationState() {
        navigationState = currentTaskNumber == 0
            ? .introduction
            : currentTaskNumber <= survey.tasks.count
                ? .task(number: currentTaskNumber, total: survey.tasks.count)
                : .completed
    }
}


// MARK: - Toolbar

/// Represents the toolbar content for the user study chat interface
struct ChatToolbar: ToolbarContent {
    @ObservedObject var viewModel: UserStudyViewModel
    let isInputDisabled: Bool
    let onDismiss: () -> Void


    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            dismissButton
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.navigationState != .completed {
                navigationButton
            }
        }
    }


    private var dismissButton: some View {
        Button(action: { viewModel.isDismissDialogPresented = true }) {
            Image(systemName: "xmark")
                .accessibilityLabel("Dismiss")
        }
        .confirmationDialog(
            "Going back will reset your chat history.",
            isPresented: $viewModel.isDismissDialogPresented,
            titleVisibility: .visible,
            actions: {
                Button("Yes", role: .destructive, action: onDismiss)
                Button("No", role: .cancel) {}
            },
            message: {
                Text("Do you want to continue?")
            }
        )
    }

    private var navigationButton: some View {
        Button {
            viewModel.isSurveyViewPresented = true
        } label: {
            Image(systemName: "arrow.forward.circle")
                .accessibilityLabel("Next Task")
        }
        .disabled(isInputDisabled)
    }
}


// MARK: - Main View

/// The main view for conducting a user study chat session
struct UserStudyChatView: View {
    @Environment(UserStudyFHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UserStudyViewModel

    private var isInputDisabled: Bool {
        interpreter.llm?.state.representation == .processing
    }

    var body: some View {
        NavigationStack {
            chatContent
                .navigationTitle(viewModel.navigationState.title)
                .toolbar {
                    ChatToolbar(
                        viewModel: viewModel,
                        isInputDisabled: isInputDisabled,
                        onDismiss: handleDismiss
                    )
                }
                .onAppear(perform: handleAppear)
                .sheet(
                    isPresented: $viewModel.isSurveyViewPresented,
                    content: surveySheet
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }


    @ViewBuilder private var chatContent: some View {
        if let llm = interpreter.llm {
            ChatView(
                Binding(
                    get: {
                        var chat = llm.context.chat
                        if viewModel.navigationState == .completed {
                            let surveyReport = viewModel.generateReport()
                            chat.append(ChatEntity(role: .hidden(type: .init(name: "SURVEY_REPORT")), content: surveyReport))
                        }
                        return chat
                    },
                    set: { llm.context.chat = $0 }
                ),
                disableInput: isInputDisabled,
                speechToText: false,
                exportFormat: viewModel.navigationState == .completed ? .text : nil,
                messagePendingAnimation: .manual(
                    shouldDisplay: shouldShowTypingIndicator(llm.context.last?.role)
                )
            )
            .viewStateAlert(state: llm.state)
            .onChange(of: llm.context, initial: true) {
                if llm.state != .generating {
                    interpreter.queryLLM()
                }
            }
        } else {
            ProgressView()
        }
    }


    /// Creates a new user study chat view
    /// - Parameter survey: The survey configuration that defines the study's tasks and structure
    init(survey: Survey) {
        _viewModel = StateObject(wrappedValue: UserStudyViewModel(survey: survey))
    }
    

    @ViewBuilder
    private func surveySheet() -> some View {
        if let task = viewModel.getCurrentTask() {
            SurveyView(
                task: task,
                isPresented: $viewModel.isSurveyViewPresented
            ) { answers in
                do {
                    try viewModel.submitSurveyAnswers(answers)
                } catch {
                    print("Error submitting answers: \(error)")
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func shouldShowTypingIndicator(_ role: LLMContextEntity.Role?) -> Bool {
        role == .user || role == .system
    }

    private func handleAppear() {
        viewModel.startSurvey()
        interpreter.resetChat()
    }

    private func handleDismiss() {
        viewModel.resetStudy()
        interpreter.resetChat()
        dismiss()
    }
}
