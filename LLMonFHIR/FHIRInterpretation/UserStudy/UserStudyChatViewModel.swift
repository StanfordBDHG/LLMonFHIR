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
final class UserStudyChatViewModel: MultipleResourcesChatViewModel, Sendable { // swiftlint:disable:this type_body_length
    /// The current state of the survey navigation
    enum NavigationState: Equatable {
        case introduction
        case task(taskId: SurveyTask.ID, taskIdx: Int, numTotalTasks: Int)
        case completed

        /// The title to display in the navigation bar based on current state
        var title: String {
            switch self {
            case .introduction:
                return "Introduction"
            case let .task(taskId: _, taskIdx, numTotalTasks):
                return "Task \(taskIdx + 1) of \(numTotalTasks)"
            case .completed:
                return "Study Completed"
            }
        }
    }
    
    enum PresentedSheet: Hashable, Identifiable {
        case instructions
        case survey
        case uploadingReport
        
        var id: some Hashable {
            self
        }
    }
    
    private let uploader: FirebaseUpload?

    /// The current navigation state of the study
    private(set) var navigationState: NavigationState = .introduction
    
    /// The currently-presented sheet
    var presentedSheet: PresentedSheet?

    /// Controls the visibility of the dismiss confirmation dialog
    var isDismissDialogPresented = false

    var isTaskIntructionButtonDisabled: Bool {
        study.tasks.first { $0.id == currentTaskId }?.instructions == nil
    }

    /// Returns the current task if one is active
    var currentTask: SurveyTask? {
        study.tasks.first { $0.id == currentTaskId }
    }
    
    var userDisplayableCurrentTaskIdx: Int? {
        study.tasks.firstIndex { $0.id == currentTaskId }.map { $0 + 1 }
    }
    
    /// Whether the chat input should currently be enabled, i.e. whether the user should currently be able to write (and submit) chat messages
    var shouldEnableChatInput: Bool {
        // Always disable during processing
        if isProcessing {
            return false
        }
        // If no capacity range is configured for this task, enable chat input
        if !hasConfiguredCapacityForCurrentTask {
            return false
        }
        // Disable when the maximum number of messages is reached
        return !isMaxAssistantMessagesReached
    }

    var shouldEnableContinueToNextTaskAction: Bool {
        if isProcessing {
            // Always disable during processing
            return false
        }
        if !hasConfiguredCapacityForCurrentTask {
            // If no capacity range is configured for this task, enable toolbar
            return true
        }
        // Disable if the minimum number of messages is not met
        return isMinAssistantMessagesReached
    }
    
    private var currentTaskId: SurveyTask.ID? {
        switch navigationState {
        case let .task(taskId, taskIdx: _, numTotalTasks: _):
            taskId
        case .introduction, .completed:
            nil
        }
    }

    let study: Study
    /// Additional key-value pairs associated with this particular study session (e.g., a participant id).
    private let userInfo: [String: String]
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
        study: Study,
        userInfo: [String: String],
        interpreter: FHIRMultipleResourceInterpreter,
        resourceSummary: FHIRResourceSummary,
        uploader: FirebaseUpload?
    ) {
        self.study = study
        self.userInfo = userInfo
        self.resourceSummary = resourceSummary
        self.uploader = uploader
        super.init(interpreter: interpreter, navigationTitle: "")
        configureMessageLimits()
    }

    
    private func updateProcessingState() async {
        switch llmSession.state {
        case .error(let error):
            // Alerts and sheets can not be displayed at the same time.
            if presentedSheet != nil {
                // We have to first dismiss all sheets.
                presentedSheet = nil
                // Wait for animation to complete
                try? await Task.sleep(for: .seconds(1))
                // Re-set the error state.
                llmSession.state = .generating
                try? await Task.sleep(for: .seconds(0.5))
                llmSession.state = .error(error: error)
            }
            processingState = .error
        default:
            processingState = await processingState.calculateNewProcessingState(basedOn: llmSession)
        }
    }

    /// Generates an assistant response if appropriate for the current context
    ///
    /// This method checks if a response is needed and if so, delegates
    /// to the interpreter to generate the actual response.
    override func generateAssistantResponse(
        preProcessingStateUpdate: @escaping () async -> Void = {}
    ) async -> LLMContextEntity? {
        let stateUpdate = {
            await self.updateProcessingState()
            await preProcessingStateUpdate()
        }
        guard let response = await super.generateAssistantResponse(preProcessingStateUpdate: stateUpdate) else {
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
    func submitSurveyAnswers(_ answers: [TaskQuestionAnswer]) throws {
        guard let currentTaskId else {
            return
        }
        taskEndTimes[currentTaskId] = Date()
        for (index, answer) in answers.enumerated() {
            try study.submitAnswer(answer, forTaskId: currentTaskId, questionIndex: index)
        }
//        presentedSheet = nil
        advanceToNextTask()
    }

    /// Resets the study to its initial state
    ///
    /// This method clears all survey answers and resets the navigation state,
    /// bringing the study back to its starting point.
    func resetStudy() {
        study.resetAllAnswers()
        taskStartTimes.removeAll()
        taskEndTimes.removeAll()
        navigationState = .introduction
    }

    /// Starts the survey portion of the study
    ///
    /// This method initializes the survey process if it hasn't already been started.
    func startSurvey() {
        guard let taskId = study.tasks.first?.id else {
            return
        }
        navigationState = .task(
            taskId: taskId,
            taskIdx: 0,
            numTotalTasks: study.tasks.count
        )
        taskStartTimes[taskId] = Date()
        presentedSheet = .instructions
    }

    /// Generates a temporary file URL containing the study report
    ///
    /// - Returns: The URL of the generated report file, or nil if generation fails
    func generateStudyReportFile() async throws -> URL? {
        guard var studyReport = await generateStudyReport() else {
            return nil
        }
        if let key = study.encryptionKey {
            studyReport = try studyReport.encrypted(using: key)
        }
        let tempDir = FileManager.default.temporaryDirectory
        let reportURL = tempDir.appendingPathComponent("survey_report_\(study.id.lowercased()).json")
        try studyReport.write(to: reportURL)
        return reportURL
    }

    private func configureMessageLimits() {
        for task in study.tasks {
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

    private func advanceToNextTask() {
        guard let currentTaskIdx = study.tasks.firstIndex(where: { $0.id == currentTaskId }) else {
            return
        }
        let nextTaskIdx = study.tasks.index(after: currentTaskIdx)
        if let nextTask = study.tasks[safe: nextTaskIdx] {
            navigationState = .task(
                taskId: nextTask.id,
                taskIdx: nextTaskIdx,
                numTotalTasks: study.tasks.count
            )
            taskStartTimes[nextTask.id] = Date()
            presentedSheet = .instructions
        } else {
            navigationState = .completed
            Task {
                presentedSheet = .uploadingReport
                await uploadReport()
                presentedSheet = nil
            }
        }
    }
    
    private func uploadReport() async {
        guard let uploader else {
            return
        }
        do {
            guard let reportFile = try await generateStudyReportFile() else {
                return
            }
            try await uploader.uploadReport(at: reportFile, for: study)
        } catch {
            print("study report upload failed: \(error)")
        }
    }


    private func generateStudyReport() async -> Data? {
        let report = UserStudyReport(
            metadata: Metadata(
                studyID: study.id,
                startTime: studyStartTime,
                endTime: Date(),
                userInfo: userInfo
            ),
            fhirResources: await getFHIRResources(),
            timeline: generateTimeline()
        )
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            return try encoder.encode(report)
        } catch {
            print("Error generating study report: \(error)")
            return nil
        }
    }

    private func generateTimeline() -> [TimelineEvent] {
        var timeline: [TimelineEvent] = interpreter.llmSession.context.chat.map { message in
            TimelineEvent.chatMessage(TimelineEvent.ChatMessage(
                timestamp: message.date,
                role: message.role.rawValue,
                content: message.content
            ))
        }
        timeline.append(contentsOf: study.tasks.compactMap { task -> TimelineEvent? in
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
        })
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
