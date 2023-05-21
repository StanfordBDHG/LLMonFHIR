//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziFHIR
import SpeziScheduler


/// A `Scheduler` using the `FHIR` standard as well as the ``LLMonFHIRTaskContext`` to schedule and manage tasks and events in the
/// LLM on FHIR Applciation.
typealias LLMonFHIRScheduler = Scheduler<FHIR, LLMonFHIRTaskContext>


extension LLMonFHIRScheduler {
    /// Creates a default instance of the ``LLMonFHIRScheduler`` by scheduling the tasks listed below.
    convenience init() {
        self.init(
            tasks: [
                Task(
                    title: String(localized: "TASK_SOCIAL_SUPPORT_QUESTIONNAIRE_TITLE"),
                    description: String(localized: "TASK_SOCIAL_SUPPORT_QUESTIONNAIRE_DESCRIPTION"),
                    schedule: Schedule(
                        start: Calendar.current.startOfDay(for: Date()),
                        repetition: .matching(.init(hour: 8, minute: 0)), // Every Day at 8:00 AM
                        end: .numberOfEvents(365)
                    ),
                    context: LLMonFHIRTaskContext.questionnaire(Bundle.main.questionnaire(withName: "SocialSupportQuestionnaire"))
                )
            ]
        )
    }
}
