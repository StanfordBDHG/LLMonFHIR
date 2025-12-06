//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

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
final class UserStudyChatViewModel: MultipleResourcesChatViewModel {  // swiftlint:disable:this type_body_length
    /// The current state of the survey navigation
    enum NavigationState: Equatable {
        case introduction
        case task(_ id: SurveyTask.ID, total: Int)
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

    /// Controls the visibility of the survey view
    private(set) var isSurveyViewPresented = false

    /// Controls the visibility of the dismiss confirmation dialog
    private(set) var isDismissDialogPresented = false

    /// Controls the visibility of the task instruction alert
    private(set) var isTaskIntructionAlertPresented = false

    var isTaskIntructionButtonDisabled: Bool {
        survey.tasks.first { $0.id == currentTaskId }?.instructions == nil
    }

    /// Returns the current task if one is active
    var currentTask: SurveyTask? {
        survey.tasks.first { $0.id == currentTaskId }
    }

    var shouldDisableChatInput: Bool {
        // Always disable during processing
        if isProcessing {
            return true
        }

        // If no capacity range is configured for this task, enable chat input
        if !hasConfiguredCapacityForCurrentTask {
            return false
        }

        // Disable when the maximum number of messages is reached
        return isMaxAssistantMessagesReached
    }

    var shouldDisableToolbarInput: Bool {
        // Always disable during processing
        if isProcessing {
            return true
        }

        // If no capacity range is configured for this task, enable toolbar
        if !hasConfiguredCapacityForCurrentTask {
            return false
        }

        // Disable if the minimum number of messages is not met
        return !isMinAssistantMessagesReached
    }
    
    private var currentTaskId: SurveyTask.ID? {
        switch navigationState {
        case .task(let id, total: _):
            id
        case .introduction, .completed:
            nil
        }
    }

    let survey: Survey
    private let resourceSummary: FHIRResourceSummary
    private let studyStartTime = Date()
    private var taskStartTimes: [SurveyTask.ID: Date] = [:]
    private var taskEndTimes: [SurveyTask.ID: Date] = [:]
    private var assistantMessagesByTask = LimitedCollectionDictionary<SurveyTask.ID, String>()

    private var isMaxAssistantMessagesReached: Bool {
        currentTaskId.map { assistantMessagesByTask.isMaxReached(forKey: $0) } ?? false
    }

    private var isMinAssistantMessagesReached: Bool {
        currentTaskId.map { assistantMessagesByTask.isMinReached(forKey: $0) } ?? false
    }

    private var hasConfiguredCapacityForCurrentTask: Bool {
        currentTaskId.map { assistantMessagesByTask.hasConfiguredCapacity(forKey: $0) } ?? false
    }


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
        self.resourceSummary = resourceSummary

        super.init(interpreter: interpreter, navigationTitle: "")
        
        configureMessageLimits()
    }

    /// Shows or hides the survey view
    func setSurveyViewPresented(_ isPresented: Bool) {
        isSurveyViewPresented = isPresented
    }

    /// Shows or hides the dismiss dialog
    func setDismissDialogPresented(_ isPresented: Bool) {
        isDismissDialogPresented = isPresented
    }
    
    /// Shows or hides the task instruction sheet
    func setTaskInstructionSheetPresented(_ isPresented: Bool) {
        isTaskIntructionAlertPresented = isPresented
    }

    func updateProcessingState() async {
        // Alerts and sheets can not be displayed at the same time.
        if case let .error(error) = llmSession.state {
            if isSurveyViewPresented || isTaskIntructionAlertPresented {
                // We have to first dismiss all sheets.
                setSurveyViewPresented(false)
                setTaskInstructionSheetPresented(false)
                // Wait for animation to complete
                try? await Task.sleep(for: .seconds(1))
                // Re-set the error state.
                llmSession.state = .generating
                try? await Task.sleep(for: .seconds(0.5))
                llmSession.state = .error(error: error)
            }
            
            processingState = .error
            return
        }
        
        processingState = await processingState.calculateNewProcessingState(basedOn: llmSession)
    }

    /// Generates an assistant response if appropriate for the current context
    ///
    /// This method checks if a response is needed and if so, delegates
    /// to the interpreter to generate the actual response.
    func generateAssistantResponse() async -> LLMContextEntity? {
        guard let response = await super.generateAssistantResponse(preProcessingStateUpdate: updateProcessingState) else {
            return nil
        }
        if let currentTaskId {
            try? assistantMessagesByTask.append(response.id.uuidString, forKey: currentTaskId)
        }
        return response
    }

    /// Cancels any ongoing operations and dismisses the current view
    ///
    /// - Parameter dismiss: The dismiss action from the environment to close the view
    func handleDismiss(dismiss: DismissAction) {
        interpreter.cancel()
        resetStudy()
        dismiss()
    }

    /// Handles the submission of survey answers for the current task
    ///
    /// This method processes the user's answers and advances to the next task
    /// in the survey sequence.
    ///
    /// - Parameter answers: Array of answers provided by the user
    /// - Throws: An error if the submission fails
    func submitSurveyAnswers(_ answers: [TaskQuestionAnswer]) async throws {
        guard let currentTaskId else {
            return
        }
        taskEndTimes[currentTaskId] = Date()
        for (index, answer) in answers.enumerated() {
            try survey.submitAnswer(answer, forTaskId: currentTaskId, questionIndex: index)
        }
        await advanceToNextTask()
        setSurveyViewPresented(false)
    }

    /// Resets the study to its initial state
    ///
    /// This method clears all survey answers and resets the navigation state,
    /// bringing the study back to its starting point.
    func resetStudy() {
        survey.resetAllAnswers()
        taskStartTimes.removeAll()
        taskEndTimes.removeAll()
        navigationState = .introduction
    }

    /// Starts the survey portion of the study
    ///
    /// This method initializes the survey process if it hasn't already been started.
    func startSurvey() {
        guard let taskId = survey.tasks.first?.id else {
            return
        }
        navigationState = .task(taskId, total: survey.tasks.count)
        taskStartTimes[taskId] = Date()
        isTaskIntructionAlertPresented = true
    }

    /// Generates a temporary file URL containing the study report
    ///
    /// - Returns: The URL of the generated report file, or nil if generation fails
    func generateStudyReportFile() async throws -> URL? {
        guard var studyReport = await generateStudyReport()?.data(using: .utf8) else {
            return nil
        }
        if let key = survey.encryptionKey {
            studyReport = try studyReport.encrypted(using: key)
        }
        let tempDir = FileManager.default.temporaryDirectory
        let reportURL = tempDir.appendingPathComponent("survey_report_\(survey.id.lowercased()).txt")
        try studyReport.write(to: reportURL)
        return reportURL
    }

    private func configureMessageLimits() {
        for task in survey.tasks {
            guard let limits = task.assistantMessagesLimit else {
                assistantMessagesByTask.setUnlimitedCapacity(forKey: task.id)
                continue
            }
            do {
                try assistantMessagesByTask.setCapacityRange(minimum: limits.lowerBound, maximum: limits.upperBound, forKey: task.id)
            } catch {
                print("Error configuring message limit for task \(task.id): \(error)")
            }
        }
    }

    private func advanceToNextTask() async {
        guard let currentTaskIdx = survey.tasks.firstIndex(where: { $0.id == currentTaskId }) else {
            return
        }
        if let nextTask = survey.tasks[safe: survey.tasks.index(after: currentTaskIdx)] {
            navigationState = .task(nextTask.id, total: survey.tasks.count)
            taskStartTimes[nextTask.id] = Date()
            isTaskIntructionAlertPresented = true
        } else {
            navigationState = .completed
        }
    }


    private func generateStudyReport() async -> String? {
        let report = UserStudyReport(
            metadata: generateMetadata(),
            fhirResources: await getFHIRResources(),
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
            studyID: survey.id,
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
            guard let taskStartTime = taskStartTimes[task.id], let taskEndTime = taskEndTimes[task.id] else {
                return nil
            }
            let surveyTask = TimelineEvent.SurveyTask(
                taskId: task.id,
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

    private func getFHIRResources() async -> FHIRResources {
        let llmRelevantResources = interpreter.fhirStore.llmRelevantResources
            .map { resource in
                FullFHIRResource(resource.versionedResource)
            }
        let allResources = await interpreter.fhirStore.allResources.mapAsync { resource in
            let summary = await resourceSummary.cachedSummary(forResource: resource)
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


extension Sequence {
    func mapAsync<Result, E>(_ transform: (Element) async throws(E) -> Result) async throws(E) -> [Result] {
        var results: [Result] = []
        results.reserveCapacity(underestimatedCount)
        for element in self {
            results.append(try await transform(element))
        }
        return results
    }
}
