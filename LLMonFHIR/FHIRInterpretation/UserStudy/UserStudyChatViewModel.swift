//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_length

import LLMonFHIRShared
import class ModelsR4.QuestionnaireResponse
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
final class UserStudyChatViewModel: Sendable {
    /// The current state of the survey navigation
    enum NavigationState: Equatable {
        case introduction
        case task(task: Study.Task, taskIdx: Int, numTotalTasks: Int, taskState: TaskState)
        case completed
        
        enum TaskState {
            case chatting
            case answeringSurvey
        }
        
        struct TitleConfig {
            let title: String
            let subtitle: String?
        }
        
        func titleConfig(in study: Study) -> TitleConfig {
            let regularConfig = switch self {
            case .introduction:
                TitleConfig(title: "Introduction", subtitle: study.title)
            case let .task(task, taskIdx, numTotalTasks, taskState: _):
                TitleConfig(
                    title: "Task \(taskIdx + 1) of \(numTotalTasks)",
                    subtitle: { () -> String in
                        if let taskTitle = task.title {
                            "\(study.title) — \(taskTitle)"
                        } else {
                            study.title
                        }
                    }()
                )
            case .completed:
                TitleConfig(title: "Study Completed", subtitle: study.title)
            }
            return switch study.chatTitleConfig {
            case .default:
                regularConfig
            case .studyTitle:
//                TitleConfig(title: study.title, subtitle: regularConfig.title)
                TitleConfig(title: study.title, subtitle: nil)
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
    
    let interpreter: FHIRMultipleResourceInterpreter
    var processingState: ProcessingState = .processingSystemPrompts
    
    /// The current navigation state of the study
    private(set) var navigationState: NavigationState = .introduction
    
    /// The currently-presented sheet
    var presentedSheet: PresentedSheet?
    
    /// Called when the firebase upload completed successfully.
    var didUploadHandler: (@MainActor () -> Void)?

    /// Controls the visibility of the dismiss confirmation dialog
    var isDismissDialogPresented = false
    
    /// Indicates if the LLM is currently processing or generating a response
    /// This property directly reflects the LLM session's state
    var isProcessing: Bool {
        llmSession.state.representation == .processing
    }
    
    let inProgressStudy: InProgressStudy
    var study: Study {
        inProgressStudy.study
    }
    /// The response to the Study's initial questionnaire, if any.
    private let initialQuestionnaireResponse: ModelsR4.QuestionnaireResponse?
    private let resourceSummary: FHIRResourceSummary
    private let studyStartTime = Date()
    private var taskStartTimes: [Study.Task.ID: Date] = [:]
    private var taskEndTimes: [Study.Task.ID: Date] = [:]
    private var assistantMessagesByTask = LimitedCollectionDictionary<Study.Task.ID, String>()
    
    
    /// Creates a new view model for managing a user study chat session
    ///
    /// - Parameters:
    ///   - survey: The survey configuration to use for this study
    ///   - interpreter: The FHIR interpreter to use for chat functionality
    ///   - resourceSummary: The FHIR resource summary provider for generating summaries of FHIR resources
    init(
        inProgressStudy: InProgressStudy,
        initialQuestionnaireResponse: ModelsR4.QuestionnaireResponse?,
        interpreter: FHIRMultipleResourceInterpreter,
        resourceSummary: FHIRResourceSummary,
        uploader: FirebaseUpload?
    ) {
        self.inProgressStudy = inProgressStudy
        self.initialQuestionnaireResponse = initialQuestionnaireResponse
        self.interpreter = interpreter
        self.resourceSummary = resourceSummary
        self.uploader = uploader
        configureMessageLimits()
    }
    
    static func unguided(
        title: String,
        interpreter: FHIRMultipleResourceInterpreter,
        resourceSummary: FHIRResourceSummary
    ) -> Self {
        let emptyStudy = Study(
            id: Study.unguidedStudyId,
            title: title,
            explainer: "",
            summarizeSingleResourcePrompt: nil,
            interpretMultipleResourcesPrompt: nil,
            chatTitleConfig: .studyTitle,
            initialQuestionnaire: nil,
            tasks: []
        )
        return Self(
            inProgressStudy: InProgressStudy(
                study: emptyStudy,
                config: .init(openAIAPIKey: "", openAIEndpoint: .regular, reportEmail: "", encryptionKey: nil),
                userInfo: [:]
            ),
            initialQuestionnaireResponse: nil,
            interpreter: interpreter,
            resourceSummary: resourceSummary,
            uploader: nil
        )
    }
    
    /// Cancels any ongoing operations and dismisses the current view
    ///
    /// - Parameter dismiss: The dismiss action from the environment to close the view
    func handleDismiss(dismiss: DismissAction) {
        interpreter.cancel()
        resetStudy()
        dismiss()
    }
    
    /// Handles the submission of survey answers for a task within the survey.
    ///
    /// This method processes the user's answers. If `task` is the current task, it also advances to the next task in the survey sequence.
    ///
    /// - parameter answers: Array of answers provided by the user
    /// - parameter task: The ``SurveyTask`` to which the answers belong.
    /// - throws: An error if the submission fails
    func submitSurveyAnswers(_ answers: [Study.Task.Question.Answer], for task: Study.Task) throws {
        let isCurrentTask = task == currentTask
        if isCurrentTask {
            taskEndTimes[task.id] = Date()
        }
        for (index, answer) in answers.enumerated() {
            try study.submitAnswer(answer, forTaskId: task.id, questionIndex: index)
        }
        if isCurrentTask {
            advanceToNextTask()
        }
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
    
    /// Starts a new conversation by clearing all user and assistant messages
    ///
    /// This preserves system messages but removes all conversation history,
    /// providing the user with a fresh chat while maintaining the interpreter context.
    func startNewConversation() {
        interpreter.startNewConversation(using: study.interpretMultipleResourcesPrompt)
    }
    
    /// Starts the survey portion of the study
    ///
    /// This method initializes the survey process if it hasn't already been started.
    func startSurvey() {
        guard let task = study.tasks.first else {
            return
        }
        navigationState = .task(
            task: task,
            taskIdx: 0,
            numTotalTasks: study.tasks.count,
            taskState: .chatting
        )
        taskStartTimes[task.id] = Date()
        presentedSheet = .instructions
    }
    
    private func advanceToNextTask() {
        guard let currentTaskIdx = study.tasks.firstIndex(where: { $0.id == currentTaskId }) else {
            return
        }
        let nextTaskIdx = study.tasks.index(after: currentTaskIdx)
        if let nextTask = study.tasks[safe: nextTaskIdx] {
            let newTaskState = { () -> NavigationState.TaskState in
                if (nextTask.instructions ?? "").isEmpty,
                   nextTask.assistantMessagesLimit == nil || nextTask.assistantMessagesLimit == 0...0,
                   !nextTask.questions.isEmpty {
                    // if the next task has no instructions and no/empty messaging limits, but does have questions, we directly go to the survey
                    .answeringSurvey
                } else {
                    // otherwise, we simply show the instructions sheet
                    .chatting
                }
            }()
            navigationState = .task(
                task: nextTask,
                taskIdx: nextTaskIdx,
                numTotalTasks: study.tasks.count,
                taskState: newTaskState
            )
            taskStartTimes[nextTask.id] = Date()
            switch newTaskState {
            case .chatting:
                presentedSheet = .instructions
            case .answeringSurvey:
                presentedSheet = .survey
            }
        } else {
            // no next task.
            navigationState = .completed
            Task {
                presentedSheet = .uploadingReport
                let didUpload = await uploadReport()
                presentedSheet = nil
                if didUpload {
                    didUploadHandler?()
                }
            }
        }
    }
    
    /// Advances the user's progression within the study.
    ///
    /// Depending on the current ``navigationState``, this function will either advance within the current task (e.g., move from the chat phase to the survey)
    /// or advance within the overall study (e.g., move from task N's survey to task N+1's instructions).
    ///
    /// If the study is already completed, this function does nothing.
    func advance() {
        switch navigationState {
        case .introduction:
            startSurvey()
        case let .task(task, taskIdx, numTotalTasks, taskState):
            switch taskState {
            case .chatting:
                if !task.questions.isEmpty {
                    // we're currently in the chat phase, and there are questions, so we start the survey
                    navigationState = .task(task: task, taskIdx: taskIdx, numTotalTasks: numTotalTasks, taskState: .answeringSurvey)
                    presentedSheet = .survey
                } else {
                    // we're in the chat phase, and there are no questions, so we go to the next task
                    advanceToNextTask()
                }
            case .answeringSurvey:
                // we're answering the survey, so advancing from there means going to the next task
                advanceToNextTask()
            }
        case .completed:
            // if we've already completed the survey, there is nowhere else to go
            return
        }
    }
}


extension UserStudyChatViewModel {
    var isTaskIntructionButtonDisabled: Bool {
        study.tasks.first { $0.id == currentTaskId }?.instructions == nil
    }
    
    /// Returns the current task if one is active
    var currentTask: Study.Task? {
        study.tasks.first { $0.id == currentTaskId }
    }
    
    private var currentTaskId: Study.Task.ID? {
        switch navigationState {
        case let .task(task, taskIdx: _, numTotalTasks: _, taskState: _):
            task.id
        case .introduction, .completed:
            nil
        }
    }
    
    var currentTaskIdx: Int? {
        study.tasks.firstIndex { $0.id == currentTaskId }
    }
    
    var userDisplayableCurrentTaskIdx: Int? {
        currentTaskIdx.map { $0 + 1 }
    }
}


extension UserStudyChatViewModel {
    /// Determines whether to display a typing indicator in the chat interface.
    var showTypingIndicator: Bool {
        processingState.isProcessing
    }
    
    // Whether the chat input should currently be enabled, i.e. whether the user should currently be able to write (and submit) chat messages
    var shouldEnableChatInput: Bool {
        // Always disable during processing
        if isProcessing {
            return false
        }
        // If no capacity range is configured for this task, enable chat input
        if !hasConfiguredCapacityForCurrentTask {
            return true
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
}


extension UserStudyChatViewModel {
    /// Direct access to the current LLM session for observing state changes
    var llmSession: any LLMSession {
        interpreter.llmSession
    }
    
    /// Provides a binding to the chat messages for use in SwiftUI views
    ///
    /// This binding allows the ChatView component to both display messages
    /// and add new user messages to the conversation.
    var chatBinding: Binding<Chat> {
        Binding { [weak self] in
            self?.interpreter.llmSession.context.chat ?? []
        } set: { [weak self] newChat in
            self?.interpreter.llmSession.context.chat = newChat
        }
    }
}


extension UserStudyChatViewModel {
    private var isMaxAssistantMessagesReached: Bool {
        currentTaskId.map { assistantMessagesByTask.isMaxReached(forKey: $0) } ?? false
    }

    private var isMinAssistantMessagesReached: Bool {
        currentTaskId.map { assistantMessagesByTask.isMinReached(forKey: $0) } ?? false
    }

    private var hasConfiguredCapacityForCurrentTask: Bool {
        currentTaskId.map { assistantMessagesByTask.hasConfiguredCapacity(forKey: $0) } ?? false
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
}


extension UserStudyChatViewModel {
    private var shouldGenerateResponse: Bool {
        if llmSession.state == .generating || isProcessing {
            return false
        }
        // Check if the last message is from a user (needs a response)
        let lastMessageIsUser = interpreter.llmSession.context.last?.role == .user
        // Check if there are no assistant messages yet (initial prompt needs a response)
        let noAssistantMessages = !interpreter.llmSession.context.contains(where: { $0.role == .assistant() })
        // Generate if last message is from user or if there are no assistant messages yet
        return lastMessageIsUser || noAssistantMessages
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
    func generateAssistantResponse() async -> LLMContextEntity? {
        let imp = { [unowned self] () async -> LLMContextEntity? in // swiftlint:disable:this unowned_variable_capture
            await updateProcessingState()
            processingState = await processingState.calculateNewProcessingState(basedOn: llmSession)
            guard shouldGenerateResponse else {
                return nil
            }
            processingState = .processingSystemPrompts
            guard let response = await interpreter.generateAssistantResponse() else {
                return nil
            }
            await updateProcessingState()
            processingState = await processingState.calculateNewProcessingState(basedOn: llmSession)
            return response
        }
        guard let response = await imp() else {
            return nil
        }
        if let currentTaskId {
            try? assistantMessagesByTask.append(response.id.uuidString, forKey: currentTaskId)
        }
        return response
    }
}


// MARK: Model + Report

extension UserStudyChatViewModel {
    /// Uploads the report using the firebase backend, if available
    ///
    /// - returns: a flag indicating whether the upload was successful.
    private func uploadReport() async -> Bool {
        guard let uploader else {
            return false
        }
        do {
            // This sleep is exclusively for cosmetic reasons;
            // it allows the "submitting response" sheet to stick around long enough for the user to read the text.
            // Otherwise, there would be no indication in the UI that the upload actually took place & succeeded.
            try await Task.sleep(for: .seconds(0.5))
            guard let reportFile = try await generateStudyReportFile(encryptIfPossible: false) else {
                return false
            }
            try await uploader.uploadReport(at: reportFile, for: study)
            return true
        } catch {
            print("study report upload failed: \(error)")
            return false
        }
    }
    
    /// Generates a temporary file URL containing the study report
    ///
    /// - Returns: The URL of the generated report file, or nil if generation fails
    func generateStudyReportFile(encryptIfPossible: Bool) async throws -> URL? {
        // IDEA: have a text-only version here (if unguided) to replicate the old MultipleResourcesChatView (ie, ChatView export) behaviour!!!
        guard var studyReport = await generateStudyReport() else {
            return nil
        }
        if encryptIfPossible, let key = inProgressStudy.config.encryptionKey {
            studyReport = try studyReport.encrypted(using: key)
        }
        let tempDir = FileManager.default.temporaryDirectory
        let reportURL = tempDir.appendingPathComponent("survey_report_\(study.id.lowercased()).json")
        try studyReport.write(to: reportURL)
        return reportURL
    }
    
    private func generateStudyReport() async -> Data? {
        let report = StudyReport(
            metadata: .init(
                studyID: study.id,
                startTime: studyStartTime,
                endTime: Date(),
                userInfo: inProgressStudy.userInfo
            ),
            initialQuestionnaireResponse: initialQuestionnaireResponse,
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

    private func generateTimeline() -> [StudyReport.TimelineEvent] {
        var timeline: [StudyReport.TimelineEvent] = interpreter.llmSession.context.chat.map { message in
            .chatMessage(.init(
                timestamp: message.date,
                role: message.role.rawValue,
                content: message.content
            ))
        }
        timeline.append(contentsOf: study.tasks.compactMap { task -> StudyReport.TimelineEvent? in
            guard let taskStartTime = taskStartTimes[task.id], let taskEndTime = taskEndTimes[task.id] else {
                return nil
            }
            return .surveyTask(.init(
                taskId: task.id,
                startedAt: taskStartTime,
                completedAt: taskEndTime,
                duration: taskEndTime.timeIntervalSince(taskStartTime),
                questions: task.questions.map { question in
                    StudyReport.TimelineEvent.SurveyQuestion(
                        questionText: question.text,
                        answer: question.answer.rawValue,
                        isOptional: question.isOptional
                    )
                }
            ))
        })
        return timeline.sorted()
    }

    private func getFHIRResources() async -> StudyReport.FHIRResources {
        let llmRelevantResources = interpreter.fhirStore.llmRelevantResources
            .map { resource in
                StudyReport.FullFHIRResource(resource.versionedResource)
            }
        let allResources = await interpreter.fhirStore.allResources.mapAsync { resource in
            let summary = await resourceSummary.cachedSummary(forResource: resource)
            return StudyReport.PartialFHIRResource(
                id: resource.id,
                resourceType: resource.resourceType,
                displayName: resource.displayName,
                dateDescription: resource.date?.description,
                summary: summary?.description
            )
        }
        return StudyReport.FHIRResources(
            llmRelevantResources: FeatureFlags.exportRawJSONFHIRResources ? llmRelevantResources : [],
            allResources: allResources
        )
    }
}


// MARK: Other

extension Study {
    static let unguidedStudyId = "edu.stanford.LLMonFHIR.unguidedStudy"
    
    var isUnguided: Bool {
        id == Self.unguidedStudyId
    }
}
