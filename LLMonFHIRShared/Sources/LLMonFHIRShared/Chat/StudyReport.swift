//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// periphery:ignore - These objects are used to create a JSON resprestation of the User Study Survey Report

public import Foundation
public import class ModelsR4.QuestionnaireResponse
public import SpeziFHIR


/// A report summarizing a user study session, including metadata, FHIR resources, and timeline events.
public struct StudyReport: Encodable, Sendable {
    /// The version of the ``StudyReport`` definition.
    ///
    /// Not used anywhere in the code, but included when the type is encoded, so that any downstream processing code can decode it in a resilient way, if we make changes down the road.
    private let version = 1
    private let metadata: Metadata
    nonisolated(unsafe) private let initialQuestionnaireResponse: ModelsR4.QuestionnaireResponse?
    private let fhirResources: FHIRResources
    private let timeline: [TimelineEvent]
    
    public init(
        metadata: Metadata,
        initialQuestionnaireResponse: ModelsR4.QuestionnaireResponse?,
        fhirResources: FHIRResources,
        timeline: [TimelineEvent]
    ) {
        self.metadata = metadata
        self.initialQuestionnaireResponse = initialQuestionnaireResponse
        self.fhirResources = fhirResources
        self.timeline = timeline
    }
}


extension StudyReport {
    /// Metadata about the study session.
    public struct Metadata: Encodable, Sendable {
        private let studyID: String
        private let startTime: Date
        private let endTime: Date
        private let userInfo: [String: String]
        
        public init(studyID: String, startTime: Date, endTime: Date, userInfo: [String : String]) {
            self.studyID = studyID
            self.startTime = startTime
            self.endTime = endTime
            self.userInfo = userInfo
        }
    }

    /// FHIR resources associated with the study, split into full and partial representations.
    public struct FHIRResources: Encodable, Sendable {
        private let llmRelevantResources: [FullFHIRResource]
        private let allResources: [PartialFHIRResource]
        
        public init(llmRelevantResources: [FullFHIRResource], allResources: [PartialFHIRResource]) {
            self.llmRelevantResources = llmRelevantResources
            self.allResources = allResources
        }
    }

    /// A wrapper for a full FHIR resource, delegating encoding to the underlying resource.
    public struct FullFHIRResource: Encodable, Sendable {
        nonisolated(unsafe) private let versionedResource: SpeziFHIR.FHIRResource.VersionedFHIRResource
        
        public init(_ versionedResource: SpeziFHIR.FHIRResource.VersionedFHIRResource) {
            self.versionedResource = versionedResource
        }
        
        public func encode(to encoder: any Encoder) throws {
            switch versionedResource {
            case .r4(let resource):
                try resource.encode(to: encoder)
            case .dstu2(let resource):
                try resource.encode(to: encoder)
            }
        }
    }

    /// A partial representation of an FHIR resource.
    public struct PartialFHIRResource: Encodable, Sendable {
        private let id: FHIRResource.ID
        private let resourceType: String
        private let displayName: String
        private let dateDescription: String?
        private let summary: String?
        
        public init(id: FHIRResource.ID, resourceType: String, displayName: String, dateDescription: String?, summary: String?) {
            self.id = id
            self.resourceType = resourceType
            self.displayName = displayName
            self.dateDescription = dateDescription
            self.summary = summary
        }
    }

    /// Represents an event in the study timeline, either a chat message or a survey task.
    public enum TimelineEvent: Hashable, Encodable, Sendable {
        case chatMessage(ChatMessage)
        case surveyTask(SurveyTask)

        private enum CodingKeys: String, CodingKey {
            case type
            case data
        }

        private enum EventType: String, Hashable, Sendable {
            case chatMessage
            case surveyTask
        }

        public struct ChatMessage: Hashable, Codable, Sendable {
            fileprivate let timestamp: Date
            private let role: String
            private let content: String
            
            public init(timestamp: Date, role: String, content: String) {
                self.timestamp = timestamp
                self.role = role
                self.content = content
            }
        }

        public struct SurveyTask: Hashable, Encodable, Sendable {
            private let taskId: String
            private let startedAt: Date
            fileprivate let completedAt: Date
            private let duration: TimeInterval
            private let questions: [SurveyQuestion]
            
            public init(taskId: String, startedAt: Date, completedAt: Date, duration: TimeInterval, questions: [SurveyQuestion]) {
                self.taskId = taskId
                self.startedAt = startedAt
                self.completedAt = completedAt
                self.duration = duration
                self.questions = questions
            }
        }

        public struct SurveyQuestion: Hashable, Encodable, Sendable {
            private let questionText: String
            private let answer: String
            private let isOptional: Bool
            
            public init(questionText: String, answer: String, isOptional: Bool) {
                self.questionText = questionText
                self.answer = answer
                self.isOptional = isOptional
            }
        }

        var timestamp: Date {
            switch self {
            case .chatMessage(let message):
                message.timestamp
            case .surveyTask(let task):
                task.completedAt
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .chatMessage(let message):
                try container.encode(EventType.chatMessage.rawValue, forKey: .type)
                try container.encode(message, forKey: .data)
            case .surveyTask(let task):
                try container.encode(EventType.surveyTask.rawValue, forKey: .type)
                try container.encode(task, forKey: .data)
            }
        }
    }
}


extension StudyReport.TimelineEvent: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
