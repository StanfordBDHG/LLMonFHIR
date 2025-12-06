//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SwiftUI


struct SurveyHomeView: View {
    private let surveyId: String
    private let survey: Survey?
    
    var body: some View {
        if let survey {
            SurveyWelcomeView(survey: survey)
        } else {
            Text(verbatim: "Unable to find survey '\(surveyId)'")
        }
    }
    
    init(surveyId: String) {
        self.surveyId = surveyId
        self.survey = Survey.withId(surveyId)
    }
}
