//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable line_length

public import LLMonFHIRShared


extension Study {
    /// LLMonFHIR's gyn study
    public static var gynStudy: Study {
        let effectivenessQuestion = Study.Task.Question(
            text: "How effective was the LLM in helping to answer your health question?",
            type: .scale(responseOptions: .effectivenessScale),
            isOptional: false
        )
        return Study(
            id: "edu.stanford.LLMonFHIR.gynStudy",
            title: "LLMonFHIR Gyn Study",
            explainer: "GYN STUDY EXPLAINER",
            settingsUnlockCode: nil,
            openAIAPIKey: "",
            openAIEndpoint: .regular,
            reportEmail: "digitalhealthresearch@stanford.edu",
            encryptionKey: nil,
            summarizeSingleResourcePrompt: nil,
            interpretMultipleResourcesPrompt: nil,
            chatTitleConfig: .default,
            initialQuestinnaire: nil,
            tasks: [
                Task(
                    id: "0",
                    title: nil,
                    instructions: "Ask a clarifying question about the most recent diagnosis from your last medical visit or any other questions you might have regarding your health?",
                    assistantMessagesLimit: 2...5,
                    questions: [
                        effectivenessQuestion
                    ]
                ),
                Task(
                    id: "1",
                    title: nil,
                    instructions: "Ask about your most recent lab work including your hormonal levels",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        effectivenessQuestion
                    ]
                ),
                Task(
                    id: "2",
                    title: nil,
                    instructions: "Ask about your current vaccination status",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        effectivenessQuestion
                    ]
                ),
                Task(
                    id: "3",
                    title: nil,
                    instructions: "Ask about vitamins and supplements",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        effectivenessQuestion
                    ]
                ),
                Task(
                    id: "4",
                    title: nil,
                    instructions: "Ask the app for a personalized health recommendation and next steps with the clinic",
                    assistantMessagesLimit: 1...5,
                    questions: [
                        effectivenessQuestion
                    ]
                ),
                Task(
                    id: "5",
                    title: nil,
                    instructions: "Before we end our session, feel free to ask the app any medical questions you might have related to your health",
                    assistantMessagesLimit: 1...5,
                    questions: Array {
                        effectivenessQuestion
                        Study.Task.Question(
                            text: "What surprised you about the LLM’s answer, either positively or negatively",
                            type: .freeText,
                            isOptional: true
                        )
                        Study.Task.Question(
                            text: "Compared to other sources of health information (e.g. websites, doctors) how do you rate the LLM’s responses?",
                            type: .scale(responseOptions: .comparisonScale),
                            isOptional: true
                        )
                        Study.Task.Question(
                            text: "What were the most and least useful features of the LLM? Do you have any suggestions to share",
                            type: .freeText,
                            isOptional: true
                        )
                        Study.Task.Question(
                            text: "How has the LLM impacted your ability to manage your health?",
                            type: .freeText,
                            isOptional: false
                        )
                        Study.Task.Question(
                            text: "On a scale of 0-10 how likely are you to recommend this tool to a friend or colleague?",
                            type: .netPromoterScore(range: 1...10),
                            isOptional: false
                        )
                    }
                ),
                Task(
                    id: "6",
                    title: nil,
                    instructions: nil,
                    assistantMessagesLimit: nil,
                    questions: finalTaskQuestions
                ),
                Task(
                    id: "7",
                    title: nil,
                    instructions: nil,
                    assistantMessagesLimit: nil,
                    questions: postInterventionQuestions
                )
            ]
        )
    }
}


private let finalTaskQuestions = [
    Study.Task.Question(text: "In the future if you had a chat bot like LLMonFHIR available…", type: .instructional),
    Study.Task.Question(
        text: "How easy would it be to access or obtain information about your medical condition?",
        type: .scale(responseOptions: .balancedEaseScale),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How frequently do you anticipate having problems learning about your medical condition because of difficulty understanding written information?",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How confident would you be in filling out medical forms by yourself?",
        type: .scale(responseOptions: .confidentnessScale),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How often do you think you would have someone help you read hospital materials?",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How often would you turn to LLMonFHIR with questions before reaching out to a healthcare professional through myHealth?",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "What questions would you feel confident consulting a chatbot like LLMonFHIR with access to your personal health record for?",
        type: .freeText,
        isOptional: false
    ),
    Study.Task.Question(
        text: "What questions would you NOT feel confident consulting a chatbot like LLMonFHIR with access to your electronic health record for?",
        type: .freeText,
        isOptional: false
    )
]


private let postInterventionQuestions = [
    Study.Task.Question(
        text: """
            Please complete the survey below.
            Thank you!
            
            Below are some statements that people sometimes make when they talk about their reproductive health. Please indicate how much you agree or disagree with each statement as it applies to you personally by circling your answer. Your answers should be what is true for you and not just what you think others want you to say.
            
            If the statement does not apply to you, select N/A. (All questions are assessed with Always, Often, Sometimes, Never)
            
            Please answer these questions based on how you feel **with access to an application** like LLMonFHIR.
            """,
        type: .instructional
    ),
    Study.Task.Question(
        text: "When all is said and done, ultimately, I am responsible for managing my reproductive journey.",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know what my next steps at the REI clinic are",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "Taking an active role in my health care is the most important thing that affects my reproductive health and ability to function",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know/ knew what the clinic needs from my partner in order to proceed",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know what each of my prescribed medications do and how to take them",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know which supplements and vitamins I need to take",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know what my hormone levels (e.g. AMH) signify",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I am confident that I can tell my health care provider/ doctor concerns I have even when he or she does not ask",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I am confident that I can tell whether I need to go get medical care or go to the doctor after my medical procedure",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I understand the description of my ultrasound",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I am confident that I know how to interpret bleedings after procedures or during my cycle and when to go see a doctor",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know the lifestyle changes like diet and exercise that are recommended",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I am confident that I can follow through on medical treatments I may need to do at home",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I am confident that I can follow through on recommendations my health care provider makes, such as changing my diet or doing regular exercise",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I have been able to maintain (keep up with) lifestyle changes that I have made for my health, like eating right or exercising",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I understand the nature and causes of my health condition(s)",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I am aware of the treatment options available throughout my reproductive journey.",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "I know how to prevent further problems with my reproductive health",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    )
]
