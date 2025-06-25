//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os.log
import SpeziAccessGuard
import SpeziFHIR
import SpeziKeychainStorage
import SpeziLLMOpenAI
import SwiftUI


struct UserStudyWelcomeView: View {
    @AppStorage(StorageKeys.resourceLimit) private var resourceLimit = StorageKeys.currentResourceCountLimit

    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @Environment(FHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(FHIRResourceSummary.self) var resourceSummary
    @Environment(KeychainStorage.self) private var keychainStorage
    @Environment(LLMOpenAIPlatform.self) private var platform

    @State private var isPresentingSettings = false
    @State private var isPresentingStudy = false
    @State private var isPresentingEarliestHealthRecords = false


    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var earliestDates: [String: Date] {
        interpreter.fhirStore.earliestDates(limit: resourceLimit)
    }

    private var earliestRecordDateFormatted: String {
        guard let date = earliestDates.values.min() else {
            return "No data available"
        }

        return dateFormatter.string(from: date)
    }


    var body: some View {
        NavigationStack {
            mainContent
                .background(Color(.systemBackground))
                .navigationTitle("Welcome")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    settingsButton
                }
                .sheet(isPresented: $isPresentingSettings) {
                    AccessGuarded(.userStudyIdentifier) {
                        SettingsView()
                    }
                }
                .fullScreenCover(isPresented: $isPresentingStudy) {
                    AccessGuarded(.userStudyIdentifier) {
                        UserStudyChatView(
                            survey: Survey(.defaultTasks),
                            interpreter: interpreter,
                            resourceSummary: resourceSummary
                        )
                    }
                }
                .sheet(isPresented: $isPresentingEarliestHealthRecords) {
                    EarliestHealthRecordsView(
                        dataSource: earliestDates,
                        dateFormatter: dateFormatter
                    )
                    .presentationDetents([.medium, .large])
                }
                    .task {
                        // Persists OpenAI token of the user study in the keychain, if no other token exists already
                        self.persistUserStudyOpenApiToken()

                        await standard.fetchRecordsFromHealthKit()
                        fhirInterpretationModule.updateSchemas()
                    }
        }
    }


    private var mainContent: some View {
        VStack {
            Spacer()
            studyLogo
            studyInformation
            Spacer()
            bottomSection
        }
    }

    private var studyLogo: some View {
        Image("StanfordBlockSTree")
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .accessibilityLabel(Text("Official Stanford Logo. Block S with Tree."))
    }

    private var studyInformation: some View {
        VStack(spacing: 24) {
            studyTitle
            studyDescription
        }
        .padding(.top, 48)
    }

    private var studyTitle: some View {
        VStack(spacing: 8) {
            Text("User Study")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("LLM on FHIR")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }

    private var studyDescription: some View {
        // swiftlint:disable:next line_length
        Text("A team member will be with you soon. During this study, you’ll complete a survey about your experiences navigating the healthcare system and have the opportunity to ask the chat questions about your health.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
    }

    private var recordsStartDateView: some View {
        Button {
            isPresentingEarliestHealthRecords = true
        } label: {
            Text("Records since: \(earliestRecordDateFormatted)")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
                .underline()
        }
        .opacity(standard.waitingState.isWaiting ? 0 : 1)
    }

    private var bottomSection: some View {
        VStack(spacing: 16) {
            startStudyButton
                .padding(.horizontal, 32)
            recordsStartDateView
                .padding(.bottom, 16)
            approvalBadge
        }
        .padding(.bottom, 24)
    }

    private var startStudyButton: some View {
        Button {
            interpreter.startNewConversation()
            isPresentingStudy = true
        } label: {
            HStack(spacing: 8) {
                if standard.waitingState.isWaiting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(standard.waitingState.isWaiting ? "Loading Resources" : "Start Session")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.accent.opacity(standard.waitingState.isWaiting ? 0.5 : 1))
            .cornerRadius(16)
        }
        .disabled(standard.waitingState.isWaiting)
    }

    private var approvalBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.secondary)
                .accessibilityLabel(Text("Checkmark"))
            Text("Approved by Stanford IRB")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }

    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { isPresentingSettings.toggle() }) {
                Image(systemName: "gear")
                    .accessibilityLabel(Text("SETTINGS"))
            }
        }
    }

    /// Persists the OpenAI token of the user study in the keychain, if no other token already exists.
    private func persistUserStudyOpenApiToken() {
        guard case let .keychain(tag, username) = self.platform.configuration.authToken else {
            fatalError("LLMonFHIR relies on an auth token stored in Keychain. Please check your `LLMOpenAIPlatform` configuration.")
        }
        
        let logger = Logger(subsystem: "edu.stanford.llmonfhir", category: "UserStudyWelcomeView")
        
        guard let apiKey = UserStudyPlistConfiguration.shared.apiKey else {
            logger.warning("No OpenAI API key found in UserStudyPlistConfiguration.shared.apiKey")
            return
        }
        
        do {
            try keychainStorage.store(
                Credentials(
                    username: username,
                    password: apiKey
                ),
                for: tag
            )
        } catch {
            logger.warning("Could not access keychain to read or store OpenAI API key: \(error)")
        }
    }
}


extension AccessGuardIdentifier {
    /// A unique identifier for user study access control.
    /// Used to protect and manage access to user study related features and views.
    static var userStudyIdentifier: Self {
        .init("UserStudyIdentifier")
    }
}

extension [SurveyTask] {
    private static let clarityScale = [
        "Very clear",
        "Somewhat clear",
        "Neither clear nor unclear",
        "Somewhat unclear",
        "Very unclear"
    ]

    private static let effectivenessScale = [
        "Very effective",
        "Somewhat effective",
        "Neither clear nor unclear",
        "Somewhat ineffective",
        "Very ineffective"
    ]
    
    private static let confidentnessScale = [
        "Very confident",
        "Somewhat confident",
        "Neither confident nor unconfident",
        "Somewhat unconfident",
        "Very unconfident"
    ]

    private static let comparisonScale = [
        "Significantly better",
        "Slightly better",
        "No change",
        "Slightly worse",
        "Significantly worse"
    ]

    private static let balancedEaseScale = [
        "Very easy",
        "Somewhat easy",
        "Neither easy nor difficult",
        "Somewhat difficult",
        "Very difficult"
    ]

    private static let frequencyOptions = [
        "Always",
        "Often",
        "Sometimes",
        "Rarely",
        "Never"
    ]

    /// Default set of survey tasks used in the user study
    static let defaultTasks: [SurveyTask] = [
        .init(
            id: 1,
            // swiftlint:disable:next line_length
            instruction: "LLMonFHIR app will have a health summary automatically generated on the home screen. Please review this before answering any questions.",
            questions: [
                .init(
                    text: "How clear and understandable was the summary provided by the app?",
                    type: .scale(responseOptions: clarityScale)
                )
            ]
        ),
        .init(
            id: 2,
            instruction: "Ask a clarifying question about the most recent diagnosis from your last medical visit.",
            questions: [
                .init(
                    text: "How effective is this feature for interpreting and evaluating your medical information?",
                    type: .scale(responseOptions: effectivenessScale)
                )
            ]
        ),
        .init(
            id: 3,
            instruction: "Ask the app for a personalized health recommendation. Feel free to ask about any health concerns.",
            questions: [
                .init(
                    text: "How effective are these recommendations in helping you make decisions about your health?",
                    type: .scale(responseOptions: effectivenessScale)
                )
            ]
        ),
        .init(
            id: 4,
            instruction: "Before we end our session, feel free to ask the app any medical questions you might have related to your health.",
            questions: [
                .init(
                    text: "How effective was the LLM in helping to answer your health question?",
                    type: .scale(responseOptions: effectivenessScale),
                    isOptional: true
                ),
                .init(
                    text: "What surprised you about the LLM's answer, either positively or negatively?",
                    type: .freeText,
                    isOptional: true
                )
            ]
        ),
        .init(
            id: 5,
            instruction: "Please feel free to ask any other questions you have. When you're done, please complete the next task.",
            questions: [
                .init(
                    text: "Compared to other sources of health information (e.g., websites, doctors), how do you rate the LLM's responses?",
                    type: .scale(responseOptions: comparisonScale)
                ),
                .init(
                    text: "What were the most and least useful features of the LLM? Do you have any suggestions to share?",
                    type: .freeText,
                    isOptional: true
                ),
                .init(
                    text: "How has the LLM impacted your ability to manage your health?",
                    type: .freeText,
                    isOptional: true
                ),
                .init(
                    text: "On a scale of 0-10, how likely are you to recommend this tool to a friend or colleague?",
                    type: .netPromoterScore(range: 0...10)
                )
            ]
        ),
        .init(
            id: 6,
            instruction: "Please hit the arrow at the top of your screen to complete the final task.",
            questions: [
                .init(
                    text: "How easy would it be to access or obtain information about your medical condition?",
                    type: .scale(responseOptions: balancedEaseScale)
                ),
                .init(
                    // swiftlint:disable:next line_length
                    text: "How frequently do you anticipate having problems learning about your medical condition because of difficulty understanding written information?",
                    type: .scale(responseOptions: frequencyOptions)
                ),
                .init(
                    text: "How confident would you be in filling out medical forms by yourself?",
                    type: .scale(responseOptions: confidentnessScale)
                ),
                .init(
                    text: "How often do you think you would have someone help you read hospital materials?",
                    type: .scale(responseOptions: frequencyOptions)
                )
            ]
        )
    ]
}
