//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

public import LLMonFHIRShared


extension Study {
    /// LLMonFHIR's usability study
    public static var pedCardioStudy: Study {
        let effectivenessQuestion = Study.Task.Question(
            text: "How effective was the LLM in helping to answer your questions concerning your child's health?",
            type: .scale(responseOptions: .effectivenessScale),
            isOptional: false
        )
        return Study(
            id: "edu.stanford.LLMonFHIR.pedCardioStudy",
            title: "LLMonFHIR PedCardio",
            explainer: "",
            summarizeSingleResourcePrompt: nil,
            interpretMultipleResourcesPrompt: .pedCardioStudySystemPrompt,
            chatTitleConfig: .default,
            initialQuestionnaire: nil,
            tasks: [
                Task(
                    id: "t1",
                    instructions: """
                        Ask a clarifying question about the most recent diagnosis from your child's last medical visit or any other questions you might have regarding your child's health?
                        """,
                    assistantMessagesLimit: 2...5, // starting at 2 bc we need to factor in the initial msg
                    questions: [
                        effectivenessQuestion
                    ]
                ),
                Task(
                    id: "t2",
                    instructions: """
                        Ask if the child is allowed to play competitive sports or participate in gym class.
                        """,
                    assistantMessagesLimit: 1...5,
                    questions: [effectivenessQuestion]
                ),
                Task(
                    id: "t3",
                    instructions: """
                        Ask the app for a personalized health recommendation for your child.
                        """,
                    assistantMessagesLimit: 1...5,
                    questions: [effectivenessQuestion]
                ),
                Task(
                    id: "t4",
                    instructions: """
                        Before we end our session, feel free to ask the app any medical questions you might have related to your child's health.
                        """,
                    assistantMessagesLimit: 1...5,
                    questions: [
                        effectivenessQuestion,
                        .init(
                            text: "What surprised you about the LLM's answer, either positively or negatively?",
                            type: .freeText,
                            isOptional: true
                        ),
                        .init(
                            text: "Compared to other sources of health information (e.g., websites, doctors), how do you rate the LLM's responses?",
                            type: .scale(responseOptions: .comparisonScale),
                            isOptional: false
                        ),
                        .init(
                            text: "What were the most and least useful features of the LLM? Do you have any suggestions to share?",
                            type: .freeText,
                            isOptional: true
                        ),
                        .init(
                            text: "How has the LLM impacted your ability to manage your child's health?",
                            type: .freeText,
                            isOptional: false
                        ),
                        .init(
                            text: "On a scale of 0–10 how likely are you to recommend this tool to a friend, colleague or other parents in general?",
                            type: .netPromoterScore(range: 0...10),
                            isOptional: false
                        )
                    ]
                ),
                Task(
                    id: "t5",
                    instructions: "Please hit the arrow at the top of your screen to complete the final task.",
                    questions: finalTaskQuestions
                ),
                Task(
                    id: "t6",
                    instructions: "",
                    questions: postInterventionQuestions
                )
            ]
        )
    }
}


private let finalTaskQuestions = [
    Study.Task.Question(
        text: "In the future if you had LLMonFHIR available…",
        type: .instructional,
        isOptional: false
    ),
    Study.Task.Question(
        text: "How easy would it be to access or obtain information about your child's medical condition?",
        type: .scale(responseOptions: .balancedEaseScale),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How frequently do you anticipate having problems learning about your child's medical condition because of difficulty understanding written information?",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How confident would you be in filling out medical forms for your child by yourself?",
        type: .scale(responseOptions: .confidentnessScale),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How often do you think you would have someone help you read hospital materials?",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    ),
    Study.Task.Question(
        text: "How often would you turn to LLMonFHIR with small questions before reaching out to a healthcare professional?",
        type: .scale(responseOptions: .frequencyOptions),
        isOptional: false
    )
]


private let postInterventionQuestions: [Study.Task.Question] = {
    let questions = [
        "When all is said and done, I am the person who is responsible for taking care of my child's health",
        "Taking an active role in my child's health care is the most important thing that affects their health and ability to function",
        "I know what each of my child's prescribed medications do and what the major or common side effects are",
        "I am confident that I can tell my child's health care provider/doctor concerns I have even when he or she does not ask",
        "I am confident that I can tell whether my child needs to go get medical care to go to the doctor or whether I can take care of a health problem",
        "I am confident I can help prevent or reduce problems associated with my child's health",
        "I know the lifestyle changes like diet and exercise that are recommended for my child's health condition",
        "I am confident that my child can follow through on medical treatments they may need to do at home",
        "I am confident that I can take actions that will help prevent or minimize some symptoms or problems associated with my child's health condition",
        "I am confident that my child can follow through on medical recommendations their health care provider makes, such as changing diet or doing regular exercise",
        "I understand the nature and causes of my child's health condition",
        "I know the different medical treatment options available for my child's health condition",
        "My child has been able to maintain (keep up with) lifestyle changes that we have made for their health, like eating right or exercising",
        "I know how to prevent further problems with my child's health",
        "I know about the self-treatments for my child's health condition",
        "I have made the changes in my child's lifestyle like diet and exercise that are recommended for their health condition",
        "I am confident I can figure out solutions when new problems arise with my child's health",
        "I am able to handle symptoms of my child's health condition on my own at home",
        "I am confident that my child can maintain lifestyle changes, like eating right and exercising, even during times of stress",
        "I am able to handle problems of my child's health condition on my own at home",
        "I am confident I can keep my child's health problems from interfering with the things my child wants to do",
        "Maintaining the lifestyle changes that are recommended for my child's health condition is too hard on a daily basis",
        "I understand the trajectory of my child's condition and why they need lifelong cardiology care",
        "I know what symptoms for which I should call my child's cardiologist immediately",
        "I understand why my child needs or needed surgery to correct their heart lesion",
        "I understand what future surgeries/interventions, if any, may be required",
        #"I now find the language and abbreviations (e.g., "VSD," "echo," "cath") used in my child's medical chart easier to navigate"#,
        "I can confidently describe my child's heart lesion"
    ]
    return [
        Study.Task.Question(
            text: """
                Please complete the survey below.
                
                Thank you!
                Below are some statements that people sometimes make when they talk about their health.
                Please indicate how much you agree or disagree with each statement as it applies to you personally by circling your answer.
                Your answers should be what is true for you and not just what you think others want you to say.
                
                If the statement does not apply to you, select N/A.
                (All questions are assessed with Always, Often, Sometimes, Rarely, Never)
                
                Please answer these questions based on how you feel with access to an application like LLMonFHIR.
                """,
            type: .instructional,
            isOptional: true
        )
    ] + questions.map {
        Study.Task.Question(text: $0, type: .scale(responseOptions: .frequencyOptions.withNA))
    }
}()


extension FHIRPrompt {
    fileprivate static let pedCardioStudySystemPrompt: Self = """
        You are the LLMonFHIR agent tasked with helping caregivers of Pediatric Cardiology patients understand their child's heart health, recent procedures, surgeries, and conditions, and answering any questions they have while accessing the child's FHIR health records for additional context.
        
        You should directly communicate with the caregiver and use the information from the health records to add context to their questions and conversation.
        
        Prioritize retrieval of historical and current EHR resources directly related to the child's cardiac care, including encounters, surgeries, catheterizations, echocardiograms, ECGs, medications, and laboratory results from the Cardiology clinic and inpatient encounters and those that involve all cardiology related departments, including and not limited to Cardiothoracic Surgery and Cardiac anesthesia departments.
        
        Additionally, retrieve relevant records from other clinical contexts only if they are known to influence heart health or surgical outcomes, such as: respiratory conditions (e.g., asthma or anatomic airway workups), genetic consultations, growth and nutrition records (e.g., failure to thrive), or renal function.
        
        Exclude unrelated medical data unless explicitly requested or clinically linked to their heart condition.
        
        Throughout the conversation, you MUST use the "get_resources" tool call to obtain the FHIR health resources necessary to answer the caregiver's question correctly.
        For example, if the caregiver asks about recent echo results, you must use the "get_resources" tool call to output the FHIR resource titles for DiagnosticReport records so you can then use them to answer.
        Use the 'get_resources' tool to get relevant health data, but focus on clear, simple explanations.
        Leave out any technical details like JSON, FHIR resources, and other implementation details.
        
        Use this information to determine the best possible FHIR resource for each question.
        Keep the requested resources to a reasonable minimum.
        
        For example, if the caregiver asks about recent hospital visits, request all recent DocumentReference and DiagnosticReport FHIR resources related to Cardiology Clinic reports and inpatient discharge summaries to obtain clinical notes, operative reports, and diagnostic reports.
        
        Interpret the resources by explaining the data relevant to the child's heart journey.
        Crucially, when interpreting lab results, vital signs, or measurements, you MUST use pediatric reference ranges appropriate for the child's specific age and weight.
        Do NOT use adult standards.
        
        If the child is recovering from surgery or undergoing medication adjustments, you may offer (but not assume) to explain the current care plan.
        Do not proactively mention medications unrelated to heart care unless clinically necessary or asked.
        
        Proactively query for more information if context is missing instead of asking the caregiver for specifics.
        Avoid too many follow-up questions.
        
        Focus heavily on clinical notes, operative notes, catheterization reports, echocardiogram reports, electrocardiogram results, and discharge summaries.
        Request recent documents early to get an overview of the child.
        
        Use simple language. Keep responses in the user's language and the present tense.
        Leave out sensitive numbers like SSN or telephone numbers.
        
        Explain medical context in language understandable by a non-medical parent, aiming for a 5th-grade reading level.
        Use words with 1 or 2 syllables when possible.
        Use less than 11 words per sentence when feasible.
        Keep responses clear and easy to read. Do not compromise accuracy.
        Provide factual, precise information in compact summaries.
        
        When explaining vital signs or lab values, give the full name (e.g., Oxygen Saturation) not just the abbreviation.
        
        Write like you are talking to a supportive friend. Use a kind, respectful, and emotionally sensitive tone.
        Acknowledge the emotional weight of caring for a child with a heart condition without assuming distress unless stated.
        
        When the caregiver asks about exercise limits or risks, ALWAYS include the child's current age, weight, and specific heart defect.
        
        Use common, simple language suitable for a parent:
        - Explain Congenital Heart Disease as a heart problem that has been present since birth
        - Explain Ventricular Septal Defect (VSD) by saying hole between the bottom heart chambers
        - Explain Atrial Septal Defect (ASD) by saying hole between the top heart chambers
        - Explain Patent Ductus Arteriosus (PDA) by saying extra blood vessel that was necessary prior to birth that stayed open
        - Explain Tetralogy of Fallot by saying a heart condition with four specific problems and explain these.
        - Explain Stenosis by saying narrowing when pertaining to a valve or a vessel
        - Explain Cyanosis by saying blue skin color from low oxygen
        - Explain Arrhythmia by saying irregular heartbeat
        - Explain Cardiomyopathy by saying weak heart muscle
        - Instead of Sternotomy, say incision on the chest bone
        - Explain Echocardiogram by saying ultrasound of the heart
        - Explain Cardiac Catheterization by saying using a thin tube to fix or check the heart
        - Explain Cardiopulmonary Bypass by saying heart-lung machine taking over during surgery
        - Explain Fontan Procedure by saying surgery to guide blood flow from the body directly to the lungs
        - Instead of Failure to Thrive, say slow weight gain
        
        Do not introduce yourself at the beginning.
        Immediately return a summary of the child based on FHIR resources, focusing on Cardiology data.
        Always start the summary by saying: “Hello caregiver of {name of child}, I understand that …”.
        (Where `{name of child}` is a placeholder for substituting in the name of the child, if known.)
        Start with an initial compact summary of the child's health information based on recent encounters and documents.
        The summary should be compact (no bullet points), holistic, empathetic but professional, and less than four sentences long.
        Add a new paragraph after the initial summary and ask the caregiver if they have any questions or where you can help them.
        """
}
