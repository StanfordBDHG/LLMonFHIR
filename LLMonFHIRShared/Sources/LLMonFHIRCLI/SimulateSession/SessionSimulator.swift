//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable attributes all

import Foundation
import LLMonFHIRShared
@_spi(APISupport) import Spezi
import SpeziLLM
import SpeziLLMOpenAI
import SpeziFHIR
import SpeziHealthKit


struct SessionSimulator: ~Copyable {
    private let config: SimulatedSessionConfig
    private let spezi: Spezi
    private let fhirStore: FHIRStore
    private let fhirInterpretation: FHIRInterpretationModule
    private let interpreter: FHIRMultipleResourceInterpreter
    private let resourceSummary: FHIRResourceSummary
    
    @MainActor
    init(config: SimulatedSessionConfig) async {
        self.config = config
        spezi = await MainActor.run {
            Spezi(from: Self.speziConfig(for: config))
        }
        fhirStore = spezi.module(FHIRStore.self)!
        fhirInterpretation = spezi.module(FHIRInterpretationModule.self)!
        interpreter = fhirInterpretation.multipleResourceInterpreter
        resourceSummary = fhirInterpretation.resourceSummary
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
        return try await _run()
    }
    
    private consuming func _run() async throws -> StudyReport {
        let startTime = Date()
        let interpretationModule = await MainActor.run { // TODO module? coordinator?
            spezi.module(FHIRInterpretationModule.self)
        }!
        let fhirStore = await MainActor.run {
            spezi.module(FHIRStore.self)
        }!
        
        await fhirStore.removeAllResources()
        await fhirStore.load(bundle: config.bundle)
        
        let interpreter = await interpretationModule.multipleResourceInterpreter!
        await interpretationModule.updateSchemas(forceImmediateUpdate: true)
        await interpreter.startNewConversation(using: config.study.interpretMultipleResourcesPrompt)
        for question in config.userQuestions {
            await MainActor.run {
                interpreter.llmSession.context.append(userInput: question)
            }
            _ = await interpreter.generateAssistantResponse()
        }
        let endTime = Date()
        return StudyReport(
            metadata: .init(
                studyID: config.study.id,
                startTime: startTime,
                endTime: endTime,
                userInfo: [:]
            ),
            initialQuestionnaireResponse: nil, // (obviously) not supported
            fhirResources: await studyReportFHIRResources(),
            timeline: await studyReportTimeline()
        )
    }
    
    
    
    @MainActor
    private func studyReportFHIRResources() async -> StudyReport.FHIRResources {
        let llmRelevantResources = fhirStore.llmRelevantResources
            .map { resource in
                StudyReport.FullFHIRResource(resource.versionedResource)
            }
        let allResources = await fhirStore.allResources.mapAsync { [resourceSummary] resource in
            let summary = await resourceSummary.cachedSummary(forResource: resource)
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
    private static func speziConfig(for config: SimulatedSessionConfig) -> Configuration {
        Configuration(standard: FakeStandard()) {
            FHIRStore()
            FHIRInterpretationModule(config: .init(
                model: config.model,
                temperature: config.temperature,
                resourceLimit: 1000,
                summarizeSingleResourcePrompt: config.study.summarizeSingleResourcePrompt,
                systemPrompt: config.study.interpretMultipleResourcesPrompt
            ))
            LLMRunner {
                LLMOpenAIPlatform(configuration: .init(
                    authToken: .constant(config.openAIKey),
                    concurrentStreams: 100,
                    retryPolicy: .attempts(3),  // Automatically perform up to 3 retries on retryable OpenAI API status codes
//                    middlewares: [OpenAIRequestInterceptor(fhirInterpretationModule)]
                ))
            }
        }
    }
}

extension Spezi {
    @MainActor
    subscript<M: Module>(_ moduleType: M.Type) -> M? {
        module(moduleType)
    }
}
