//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

public import LLMonFHIRShared


extension Study {
    public static var usabilityStudy: Study {
        Study(
            id: "edu.stanford.LLMonFHIR.usabilityStudy",
            title: "LLMonFHIR User Study",
            explainer: "During this study, you’ll complete a survey about your experiences navigating the healthcare system and have the opportunity to ask the chat questions about your health.",
            settingsUnlockCode: nil,
            openAIAPIKey: "",
            openAIEndpoint: .regular,
            reportEmail: "digitalhealthresearch@stanford.edu",
            encryptionKey: nil,
            summarizeSingleResourcePrompt: nil,
            interpretMultipleResourcesPrompt: nil,
            tasks: [
                SurveyTask(
                    id: "Welcome",
                    title: "Welcome",
                    instructions: "LLMonFHIR app will have a health summary automatically generated on the home screen. Please review this before answering any questions.",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        TaskQuestion(
                            text: "How clear and understandable was the summary provided by the app?",
                            type: .scale(responseOptions: .clarityScale)
                        )
                    ]
                ),
                SurveyTask(
                    id: "2",
                    title: nil,
                    instructions: "Ask a clarifying question about the most recent diagnosis from your last medical visit.",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        TaskQuestion(
                            text: "How effective is this feature for interpreting and evaluating your medical information?",
                            type: .scale(responseOptions: .effectivenessScale)
                        )
                    ]
                ),
                SurveyTask(
                    id: "3",
                    title: nil,
                    instructions: "Ask the app for a personalized health recommendation. Feel free to ask about any health concerns.",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        TaskQuestion(
                            text: "How effective are these recommendations in helping you make decisions about your health?",
                            type: .scale(responseOptions: .effectivenessScale)
                        )
                    ]
                ),
                SurveyTask(
                    id: "4",
                    title: nil,
                    instructions: "Before we end our session, feel free to ask the app any medical questions you might have related to your health.",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        TaskQuestion(
                            text: "How effective was the LLM in helping to answer your health question?",
                            type: .scale(responseOptions: .effectivenessScale),
                            isOptional: true
                        ),
                        TaskQuestion(
                            text: "What surprised you about the LLM's answer, either positively or negatively?",
                            type: .freeText,
                            isOptional: true
                        ),
                    ]
                ),
                SurveyTask(
                    id: "5",
                    title: nil,
                    instructions: "Please feel free to ask any other questions you have. When you're done, please complete the next task.",
                    assistantMessagesLimit: nil,
                    questions: [
                        TaskQuestion(
                            text: "Compared to other sources of health information (e.g., websites, doctors), how do you rate the LLM's responses?",
                            type: .scale(responseOptions: .comparisonScale),
                            isOptional: false
                        ),
                        TaskQuestion(
                            text: "What were the most and least useful features of the LLM? Do you have any suggestions to share?",
                            type: .freeText,
                            isOptional: true
                        ),
                        TaskQuestion(
                            text: "How has the LLM impacted your ability to manage your health?",
                            type: .freeText,
                            isOptional: true
                        ),
                        TaskQuestion(
                            text: "On a scale of 0-10, how likely are you to recommend this tool to a friend or colleague?",
                            type: .netPromoterScore(range: 0...10),
                            isOptional: false
                        ),
                    ]
                ),
                SurveyTask(
                    id: "6",
                    title: nil,
                    instructions: "Please hit the arrow at the top of your screen to complete the final task.",
                    assistantMessagesLimit: nil,
                    questions: [
                        TaskQuestion(
                            text: "How easy would it be to access or obtain information about your medical condition?",
                            type: .scale(responseOptions: .balancedEaseScale),
                            isOptional: false
                        ),
                        TaskQuestion(
                            text: "How frequently do you anticipate having problems learning about your medical condition because of difficulty understanding written information?",
                            type: .scale(responseOptions: .frequencyOptions),
                            isOptional: false
                        ),
                        TaskQuestion(
                            text: "How confident would you be in filling out medical forms by yourself?",
                            type: .scale(responseOptions: .confidentnessScale),
                            isOptional: false
                        ),
                        TaskQuestion(
                            text: "How often do you think you would have someone help you read hospital materials?",
                            type: .scale(responseOptions: .frequencyOptions),
                            isOptional: false
                        )
                    ]
                )
            ]
        )
    }
}
