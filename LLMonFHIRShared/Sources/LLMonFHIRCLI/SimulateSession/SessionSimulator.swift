//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import LLMonFHIRShared
import OpenAPIRuntime
@_spi(APISupport) import Spezi
import SpeziFHIR
import SpeziHealthKit
import SpeziLLM
import SpeziLLMOpenAI


struct SessionSimulator: ~Copyable {
    private let config: SimulatedSessionConfig
    private let runIdx: Int
    private let spezi: Spezi
    private let fhirStore: FHIRStore
    private let coordinator: SessionCoordinator
    private let interpreter: FHIRMultipleResourceInterpreter
    private let resourceSummarizer: FHIRResourceSummarizer

    var sessionDesc: String {
        "\(config.study.id) / \(config.bundle.singlePatient?.fullName ?? config.bundleInputName) @ \(config.model)/\(config.temperature) (\(runIdx + 1)/\(config.numberOfRuns))"
    }

    @MainActor
    init(config: SimulatedSessionConfig, runIdx: Int) {
        self.config = config
        self.runIdx = runIdx
        spezi = Spezi(from: Self.speziConfig(for: config))
        coordinator = spezi.module(SessionCoordinator.self)! // swiftlint:disable:this force_unwrapping
        fhirStore = coordinator.fhirStore
        interpreter = coordinator.multipleResourceInterpreter
        resourceSummarizer = coordinator.resourceSummarizer
    }
    
    @concurrent
    consuming func run() async throws -> StudyReport {
        // start (& stop) service modules
        let speziService = Task { [spezi] in
            await spezi.run()
        }
        defer {
            speziService.cancel()
        }
        let sessionDesc = self.sessionDesc
        return try await _run()
    }
    
    private consuming func _run() async throws -> StudyReport {
        let startTime = Date()
        await fhirStore.removeAllResources()
        await fhirStore.load(bundle: config.bundle)
        await coordinator.prepareForUse()
        await interpreter.startNewConversation(using: config.systemPrompt)
        for question in config.userQuestions {
            await MainActor.run {
                interpreter.llmSession.context.append(userInput: question)
            }
            _ = try await interpreter.generateAssistantResponse()
        }
        let endTime = Date()
        return StudyReport(
            metadata: .init(
                studyID: config.study.id,
                startTime: startTime,
                endTime: endTime,
                userInfo: [
                    "bundle": self.config.bundleInputName
                ],
                llmConfig: .init(
                    model: config.model,
                    temperature: config.temperature
                )
            ),
            initialQuestionnaireResponse: nil, // (obviously) not supported
            fhirResources: await studyReportFHIRResources(),
            timeline: await studyReportTimeline()
        )
    }

    @MainActor
    private func studyReportFHIRResources() async -> StudyReport.FHIRResources {
        let llmRelevantResources = fhirStore.llmRelevantResources
            .map { StudyReport.FullFHIRResource($0.versionedResource) }
        let allResources = await fhirStore.allResources.mapAsync { [resourceSummarizer] resource in
            let summary = await resourceSummarizer.cachedSummary(forResource: resource)
            return StudyReport.PartialFHIRResource(
                id: resource.id,
                resourceType: resource.resourceType,
                displayName: resource.displayName,
                dateDescription: resource.date?.description,
                summary: summary?.description
            )
        }
        return .init(
            llmRelevantResources: llmRelevantResources,
            allResources: allResources
        )
    }
    
    @MainActor
    private func studyReportTimeline() -> [StudyReport.TimelineEvent] {
        interpreter.llmSession.context.chat.map { message in
            .chatMessage(.init(
                timestamp: message.date,
                role: message.role.rawValue,
                content: message.content
            ))
        }
    }
}


extension SessionSimulator {
    private actor FakeStandard: Standard, HealthKitConstraint {
        func handleNewSamples<Sample>(
            _ addedSamples: some Collection<Sample> & Sendable,
            ofType sampleType: SampleType<Sample>
        ) {}
        
        func handleDeletedObjects<Sample>(
            _ deletedObjects: some Collection<HKDeletedObject> & Sendable,
            ofType sampleType: SampleType<Sample>
        ) {}
    }
    
    @MainActor
    private static func speziConfig(for config: SimulatedSessionConfig) -> SpeziConfiguration {
        let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        let middlewares: [any ClientMiddleware]
        switch config.service {
        case .openAI:
            middlewares = []
        case .firebase:
            middlewares = firebaseConfigFromEnvironment().map {
                [OpenAIFirebaseInterceptor(firebaseConfig: $0, endpointProvider: { .firebaseFunction(name: "chat") })]
            } ?? []
        case .firebaseEmulator:
            middlewares = [
                OpenAIFirebaseInterceptor(
                    firebaseConfig: emulatorConfigFromEnvironment(),
                    endpointProvider: { .firebaseFunction(name: "chat") }
                )
            ]
        }
        return SpeziConfiguration(standard: FakeStandard()) {
            FHIRStore()
            SessionCoordinator(config: .init(
                model: config.model,
                temperature: config.temperature,
                resourceLimit: 1000,
                summarizeSingleResourcePrompt: config.study.summarizeSingleResourcePrompt,
                systemPrompt: config.systemPrompt
            ))
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(
                    authToken: .constant(openAIKey),
                    concurrentStreams: 100,
                    retryPolicy: .attempts(3),
                    middlewares: middlewares
                ))
            }
        }
    }

    /// Loads a `FirebaseConfig` from the `GOOGLE_CREDENTIALS_PLIST` environment variable.
    /// Returns `nil` when the variable is unset or the file cannot be parsed.
    private static func firebaseConfigFromEnvironment() -> FirebaseConfig? {
        guard let plistPath = ProcessInfo.processInfo.environment["GOOGLE_CREDENTIALS_PLIST"] else {
            return nil
        }
        return try? FirebaseConfig(contentsOfFile: plistPath)
    }

    /// Builds a `FirebaseConfig` that routes all traffic to the local Firebase emulator suite.
    ///
    /// Reads `FIREBASE_AUTH_EMULATOR_HOST` and `FIREBASE_FUNCTIONS_EMULATOR_HOST` for the emulator
    /// addresses (defaulting to `localhost:9099` and `localhost:5001` respectively). If
    /// `GOOGLE_CREDENTIALS_PLIST` is set, the real project credentials are used; otherwise
    /// placeholder values are substituted so the emulator can be used without any credentials file.
    private static func emulatorConfigFromEnvironment() -> FirebaseConfig {
        let env = ProcessInfo.processInfo.environment
        let base = firebaseConfigFromEnvironment()
        return FirebaseConfig(
            apiKey: base?.apiKey ?? "demo-key",
            projectID: base?.projectID ?? "demo-project",
            authEmulatorAddress: env["FIREBASE_AUTH_EMULATOR_HOST"] ?? "localhost:9099",
            functionsEmulatorAddress: env["FIREBASE_FUNCTIONS_EMULATOR_HOST"] ?? "localhost:5001"
        )
    }
}
