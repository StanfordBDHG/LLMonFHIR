//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFHIR


// periphery:ignore - These objects are used to create a JSON resprestation of the User Study Survey Report
extension UserStudyChatViewModel {
    /// A report summarizing a user study session, including metadata, FHIR resources, and timeline events.
    struct UserStudyReport: Encodable {
        let metadata: Metadata
        let fhirResources: FHIRResources
        let timeline: [TimelineEvent]
    }

    /// Metadata about the study session.
    struct Metadata: Encodable {
        let studyID: String
        let startTime: Date
        let endTime: Date
    }

    /// FHIR resources associated with the study, split into full and partial representations.
    struct FHIRResources: Encodable {
        let llmRelevantResources: [FullFHIRResource]
        let allResources: [PartialFHIRResource]
    }

    /// A wrapper for a full FHIR resource, delegating encoding to the underlying resource.
    struct FullFHIRResource: Encodable {
        private let versionedResource: SpeziFHIR.FHIRResource.VersionedFHIRResource


        init(_ versionedResource: SpeziFHIR.FHIRResource.VersionedFHIRResource) {
            self.versionedResource = versionedResource
        }


        func encode(to encoder: Encoder) throws {
            switch versionedResource {
            case .r4(let resource):
                try resource.encode(to: encoder)
            case .dstu2(let resource):
                try resource.encode(to: encoder)
            }
        }
    }

    /// A partial representation of an FHIR resource.
    struct PartialFHIRResource: Encodable {
        let id: String
        let resourceType: String
        let displayName: String
        let dateDescription: String?
        let summary: String?
    }

    /// Represents an event in the study timeline, either a chat message or a survey task.
    enum TimelineEvent: Encodable {
        case chatMessage(ChatMessage)
        case surveyTask(SurveyTask)

        private enum CodingKeys: String, CodingKey {
            case type
            case data
        }

        private enum EventType: String {
            case chatMessage
            case surveyTask
        }

        struct ChatMessage: Codable {
            let timestamp: Date
            let role: String
            let content: String
        }

        struct SurveyTask: Encodable {
            let taskNumber: Int
            let startedAt: Date
            let completedAt: Date
            let duration: TimeInterval
            let questions: [SurveyQuestion]
        }

        struct SurveyQuestion: Encodable {
            let questionText: String
            let answer: String
            let isOptional: Bool
        }

        var timestamp: Date {
            switch self {
            case .chatMessage(let message): return message.timestamp
            case .surveyTask(let task): return task.completedAt
            }
        }

        func encode(to encoder: Encoder) throws {
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
