//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziChat
import SpeziLLM
import SwiftUI


/// View model for the UserStudyChatView.
///
/// This view model coordinates between the UI and the FHIRMultipleResourceInterpreter.
/// It provides UI-specific computed properties and methods while delegating
/// LLM operations and persistence to the underlying interpreter.
@MainActor
@Observable
final class UserStudyChatViewModel {
    // MARK: - Navigation State

    /// The current state of the survey navigation
    enum NavigationState: Equatable {
        case introduction
        case task(number: Int, total: Int)
        case completed

        /// The title to display in the navigation bar based on current state
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
    private(set) var navigationState: NavigationState = .introduction

    /// Indicates whether the survey portion has been started
    private(set) var isSurveyStarted = false

    /// The generated study report JSON, available when the study is completed
    private(set) var studyReport: String?

    /// Controls the visibility of the survey view
    var isSurveyViewPresented = false

    /// Controls the visibility of the dismiss confirmation dialog
    var isDismissDialogPresented = false

    /// Controls the visibility of the sharing sheet for exporting the study report
    var isSharingSheetPresented = false

    private let survey: Survey
    private let interpreter: FHIRMultipleResourceInterpreter
    private let resourceSummary: FHIRResourceSummary

    private var currentTaskNumber: Int = 0 {
        didSet {
            updateNavigationState()
        }
    }

    /// Direct access to the current LLM session for observing state changes
    var llmSession: LLMSession {
        interpreter.llmSession
    }

    /// Indicates if the LLM is currently processing or generating a response
    /// This property directly reflects the LLM session's state
    var isProcessing: Bool {
        llmSession.state.representation == .processing
    }

    /// Determines whether to display a typing indicator in the chat interface.
    var showTypingIndicator: Bool {
        let role = llmSession.context.last?.role
        return role == .user || role == .system
    }

    /// Provides a binding to the chat messages for use in SwiftUI views
    ///
    /// This binding allows the ChatView component to both display messages
    /// and add new user messages to the conversation. It also adds survey
    /// report data when the survey is completed.
    var chatBinding: Binding<Chat> {
        Binding(
            get: { [weak self] in
                self?.interpreter.llmSession.context.chat ?? []
            },
            set: { [weak self] newChat in
                self?.interpreter.llmSession.context.chat = newChat
            }
        )
    }

    private var shouldGenerateResponse: Bool {
        if llmSession.state == .generating || isProcessing {
            return false
        }

        // Check if the last message is from a user (needs a response)
        let lastMessageIsUser = interpreter.llmSession.context.last?.role == .user

        // Check if there are no assistant messages yet (initial prompt needs a response)
        let noAssistantMessages = !interpreter.llmSession.context.contains(where: { $0.role == .assistant() })

        return (lastMessageIsUser || noAssistantMessages)
    }

    private let studyStartTime = Date()
    private let studyID = UUID().uuidString
    private var taskStartTimes: [Int: Date] = [:]
    private var taskEndTimes: [Int: Date] = [:]
    private var resourceAccessTimes: [String: Date] = [:]

    /// Creates a new view model for managing a user study chat session
    ///
    /// - Parameters:
    ///   - survey: The survey configuration to use for this study
    ///   - interpreter: The FHIR interpreter to use for chat functionality
    ///   - resourceSummary: The FHIR resource summary provider for generating summaries of FHIR resources
    init(
        survey: Survey,
        interpreter: FHIRMultipleResourceInterpreter,
        resourceSummary: FHIRResourceSummary
    ) {
        self.survey = survey
        self.interpreter = interpreter
        self.resourceSummary = resourceSummary
    }


    /// Generates an assistant response if appropriate for the current context
    ///
    /// This method checks if a response is needed and if so, delegates
    /// to the interpreter to generate the actual response.
    func generateAssistantResponse() {
        guard shouldGenerateResponse else {
            return
        }
        interpreter.generateAssistantResponse()
    }

    /// Cancels any ongoing operations and dismisses the current view
    ///
    /// - Parameter dismiss: The dismiss action from the environment to close the view
    func handleDismiss(dismiss: DismissAction) {
        interpreter.cancel()
        resetStudy()
        dismiss()
    }

    // MARK: - Survey Methods

    /// Handles the submission of survey answers for the current task
    ///
    /// This method processes the user's answers and advances to the next task
    /// in the survey sequence.
    ///
    /// - Parameter answers: Array of answers provided by the user
    /// - Throws: An error if the submission fails
    func submitSurveyAnswers(_ answers: [TaskQuestionAnswer]) throws {
        taskEndTimes[currentTaskNumber] = Date()

        for (index, answer) in answers.enumerated() {
            try survey.submitAnswer(answer, forTaskId: currentTaskNumber, questionIndex: index)
        }

        advanceToNextTask()
    }

    /// Resets the study to its initial state
    ///
    /// This method clears all survey answers and resets the navigation state,
    /// bringing the study back to its starting point.
    func resetStudy() {
        survey.resetAllAnswers()
        currentTaskNumber = 0
        isSurveyStarted = false
        updateNavigationState()
    }

    /// Starts the survey portion of the study
    ///
    /// This method initializes the survey process if it hasn't already been started.
    func startSurvey() {
        if isSurveyStarted {
            return
        }
        isSurveyStarted = true
        currentTaskNumber = 1
        taskStartTimes[currentTaskNumber] = Date()
    }

    /// Returns the current task if one is active
    ///
    /// - Returns: The current survey task, if available
    func getCurrentTask() -> SurveyTask? {
        survey.tasks.first { $0.id == currentTaskNumber }
    }

    /// Generates a temporary file URL containing the study report
    ///
    /// - Returns: The URL of the generated report file, or nil if generation fails
    func generateStudyReportFile() -> URL? {
        guard let studyReport = generateStudyReport() else {
            return nil
        }

        let tempDir = FileManager.default.temporaryDirectory
        let reportURL = tempDir.appendingPathComponent("survey_report_\(studyID.lowercased()).txt")
        try? studyReport.write(to: reportURL, atomically: true, encoding: .utf8)
        return reportURL
    }


    private func advanceToNextTask() {
        if currentTaskNumber < survey.tasks.count {
            currentTaskNumber += 1
            taskStartTimes[currentTaskNumber] = Date()
        } else {
            navigationState = .completed
            studyReport = generateStudyReport()
        }
    }

    private func updateNavigationState() {
        navigationState = currentTaskNumber == 0
            ? .introduction
            : currentTaskNumber <= survey.tasks.count
                ? .task(number: currentTaskNumber, total: survey.tasks.count)
                : .completed
    }

    private func generateStudyReport() -> String? {
        let report = UserStudyReport(
            metadata: generateMetadata(),
            fhirResources: getFHIRResources(),
            timeline: generateTimeline()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try encoder.encode(report)
            let string = String(data: data, encoding: .utf8)
            return string
        } catch {
            print("Error generating study report: \(error)")
            return nil
        }
    }

    private func generateMetadata() -> Metadata {
        Metadata(
            studyID: studyID,
            startTime: studyStartTime,
            endTime: Date()
        )
    }

    private func generateTimeline() -> [TimelineEvent] {
        var timeline: [TimelineEvent] = []

        let chatMessages = interpreter.llmSession.context.chat.map { message in
            TimelineEvent.chatMessage(TimelineEvent.ChatMessage(
                timestamp: message.date,
                role: message.role.rawValue,
                content: message.content
            ))
        }

        timeline.append(contentsOf: chatMessages)

        let surveyTasks = survey.tasks.compactMap { task -> TimelineEvent? in
            let taskNumber = task.id
            guard let taskStartTime = taskStartTimes[taskNumber], let taskEndTime = taskEndTimes[taskNumber] else {
                return nil
            }
            
            let surveyTask = TimelineEvent.SurveyTask(
                taskNumber: taskNumber,
                startedAt: taskStartTime,
                completedAt: taskEndTime,
                duration: taskEndTime.timeIntervalSince(taskStartTime),
                questions: task.questions.map { question in
                    TimelineEvent.SurveyQuestion(
                        questionText: question.text,
                        answer: question.answer.rawValue,
                        isOptional: question.isOptional
                    )
                }
            )
            
            return TimelineEvent.surveyTask(surveyTask)
        }
        
        timeline.append(contentsOf: surveyTasks)
        
        return timeline.sorted { $0.timestamp < $1.timestamp }
    }

    private func getFHIRResources() -> FHIRResources {
        let llmRelevantResources = interpreter.fhirStore.llmRelevantResources
            .map { resource in
                FullFHIRResource(resource.versionedResource)
            }

        let allResources = interpreter.fhirStore.allResources
            .map { resource in
                let summary = resourceSummary.cachedSummary(forResource: resource)
                return PartialFHIRResource(
                    id: resource.id,
                    resourceType: resource.resourceType,
                    displayName: resource.displayName,
                    dateDescription: resource.date?.description,
                    summary: summary?.description
                )
            }

        return FHIRResources(
            llmRelevantResources: FeatureFlags.exportRawJSONFHIRResources ? llmRelevantResources : [],
            allResources: allResources
        )
    }
}

extension ChatEntity.Role {
    var rawValue: String {
        switch self {
        case .user: "user"
        case .assistant: "assistant"
        case .assistantToolCall: "assistant_tool_call"
        case .assistantToolResponse: "assistant_tool_response"
        case .hidden(let type): "hidden_\(type.name)"
        }
    }
}
