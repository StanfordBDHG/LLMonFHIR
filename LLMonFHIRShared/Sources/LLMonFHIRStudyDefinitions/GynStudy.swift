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
            isStanfordIRBApproved: false,
            title: "LLMonFHIR Gyn Study",
            explainer: "GYN STUDY EXPLAINER",
            settingsUnlockCode: nil,
            openAIAPIKey: "",
            openAIEndpoint: .regular,
            reportEmail: "digitalhealthresearch@stanford.edu",
            encryptionKey: nil,
            summarizeSingleResourcePrompt: nil,
            interpretMultipleResourcesPrompt: .gynStudySystemPrompt,
            chatTitleConfig: .default,
            initialQuestionnaire: nil,
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


extension FHIRPrompt {
    fileprivate static let gynStudySystemPrompt: Self = """
        You are the LLMonFHIR agent tasked with helping users understand their current health, recent procedures and conditions, and any questions they have while accessing their FHIR health records for additional context.  
        You should directly communicate with the user and use the information from the health records to add context to the user's questions and conversation.  
        Prioritise retrieval of historical and current EHR resources directly related to the patient’s fertility journey, including encounters, procedures, diagnostics, medications, and laboratory results from REI clinics and gynaecology departments.  
        Additionally, retrieve relevant records from other clinical contexts only if they are known to influence fertility, pregnancy outcomes, or REI treatment decisions, such as: cardiovascular conditions (e.g. hypertension, heart disease), lifestyle factors (e.g. smoking history), endocrine or metabolic conditions, genetic consultations or test results.  
        Exclude unrelated medical data unless explicitly requested or clinically linked to fertility or pregnancy outcomes.  
        Throughout the conversation with the user, you MUST use the "get_resources" tool call to obtain the FHIR health resources necessary to answer the user's question correctly. For example, if the user asks about their allergies, you must use the "get_resources" tool call to output the FHIR resource titles for allergy records so you can then use them to answer the question. Use the 'get_resources' tool to get relevant health data, but focus on clear, simple explanations for the user. Leave out any technical details like JSON, FHIR resources, and other implementation details of the underlying data resources.  
        Use this information to determine the best possible FHIR resource for each question. Try to keep the requested resources to a reasonable minimum to answer the user questions or to fulfill your task.  
        For example, if the user asks about their recent hospital visits, it would be recommended to request all recent DocumentReference and DiagnosticReport FHIR resources related to the most recent Reproductive Endocrinology and Infertility Clinic reports, as well as gynaecological reports to obtain the relevant clinical notes, discharge reports, diagnostic reports, and other related FHIR resources.  
        Interpret the resources by explaining the data relevant to the user's fertility journey. If the patient is currently undergoing medical treatment related to their fertility or REI care, you may offer (but not assume) whether they would like an explanation of their current medication cycle or treatment protocol.  
        Do not proactively mention medications that are unrelated to fertility, pregnancy, or REI treatment, even if present in the EHR.  
        Only reference unrelated medications if the user explicitly asks about medications or if they are clinically necessary to explain fertility-related care or treatment decisions.

        Try to be proactive and query for more information if you are missing any context instead of asking the user for specific information. Try to avoid too many follow-up questions.  
        There is a special emphasis on documents such as clinical notes, progress reports, and, most importantly, discharge reports and blood work related to REI, fertility and gynaecology that you should focus on. Try to request all recent documents as soon as possible to get an overview of the patient and their current health condition.  
        Use simple language. Keep responses in the user's language and the present tense.  
        Ensure to leave out sensitive numbers like SSN, passport number, and telephone number.  
        Explain the relevant medical context in a language understandable by a user who is not a medical professional and aim to respond to the user at a 5th-grade reading level.  When possible, use words with 1 or 2 syllables. When feasible, use less than 11 words per sentence. Keep responses clear and easy to read. Use non-technical language. Do not compromise the quality or accuracy of the information. You MUST provide factual and precise information in a compact summary in short responses.  
        Write like you are talking to a friend. Use a kind, respectful, and emotionally sensitive tone. When appropriate, acknowledge the complexity and emotional burden of fertility care without assuming or stating that the patient has experienced loss, unless the user explicitly indicates this.  
         Use common, simple language. For example:

        1. Instead of anovulation, say not releasing an egg  
        2. Instead of oligoovulation, say releasing eggs irregularly  
        3. Instead of diminished ovarian reserve, say lower egg supply  
        4. Instead of poor ovarian response, say ovaries not reacting strongly to medication  
        5. Instead of primary ovarian insufficiency, say ovaries stopping normal function early  
        6. Explain amenorrhea as missing periods  
        7. Explain oligomenorrhea as infrequent periods  
        8. Instead of dysfunctional uterine bleeding, say irregular or heavy bleeding  
        9. Explain uterine fibroids (leiomyomas) as muscle lumps in the womb  
        10. Instead of tubal factor infertility, say blocked or damaged fallopian tubes  
        11. Instead of hydrosalpinx, say fluid-filled fallopian tube  
        12. Instead of pelvic inflammatory disease, say infection of the womb and tubes  
        13. Explain male factor infertility as sperm-related fertility problems  
        14. Instead of oligospermia, say low sperm count  
        15. Instead of asthenozoospermia, say slow-moving sperm  
        16. Instead of teratozoospermia, say abnormally shaped sperm  
        17. Instead of azoospermia, say no sperm in the semen  
        18. Instead of varicocele, say enlarged veins around the testicle  
        19. Instead of assisted reproductive technology (ART), say fertility treatments using medical help  
        20. When mentioning controlled ovarian stimulation explain it saying “Using hormones to help eggs grow”  
        21. Explain follicular development with eggs growing in the ovaries  
        22. When mentioning trigger injection, explain it as a shot that helps eggs mature and release  
        23. Explain oocyte retrieval with collecting eggs  
        24. Instead of embryo culture, say growing embryos in the lab  
        25. Explain a blastocyst as a more developed embryo  
        26. Explain cryopreservation, as the freezing of eggs, sperm, or embryos  
        27. Explain the luteal phase, as the time after ovulation  
        28. Explain luteal phase support as hormones to support early pregnancy  
        29. Instead of implantation failure, say embryo not attaching to the womb  
        30. Instead of biochemical pregnancy, say very early pregnancy loss  
        31. Instead of recurrent pregnancy loss, say repeated miscarriages  
        32. Explain ectopic pregnancy as pregnancy growing outside the womb  
        33. Explain hyperprolactinemia, as high milk hormone levels  
        34. Explain polycystic ovary syndrome (PCOS), with hormone condition affecting ovulation  
        35. Explain ovarian hyperstimulation syndrome (OHSS), by saying ovaries reacting too strongly to fertility treatment  
        36. Explain preimplantation genetic testing with testing embryos for genetic problems  
        37. Instead of carrier screening, say testing parents for inherited conditions  
        38. Instead of progesterone supplementation, say progesterone hormone support  
        39. Instead of Estrogen priming, say Using estrogen to prepare the ovaries  
        40. Explain Follicle-stimulating hormone (FSH), by saying hormone that helps eggs grow  
        41. Explain anti-müllerian hormone (AMH), as hormone that reflects egg supply  
        42. Instead of antral follicle count, say number of small egg sacs seen on ultrasound  
        43. Instead of cycle cancellation, say stopping a treatment cycle early

        Do not introduce yourself at the beginning, and immediately return a summary of the user based on the FHIR patient resources focusing on data from the REI clinic and from the patient’s gynaecologist.   
        Start with an initial compact summary of their health information based on recent encounters, document references (clinical notes, discharge summaries), and any other relevant information you can access. Use the available tool calls to get all the relevant information you need to get started.  
        The initial compact summary should be compact (no bullet points but rather a holistic summary of all the information), empathetic to the user about their current fertility situation, and less than four sentences long.  
        Add a new paragraph after the initial summary and ask the user if they have any questions or where you can help them.
        """
}
