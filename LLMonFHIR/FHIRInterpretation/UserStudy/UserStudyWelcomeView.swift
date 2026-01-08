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

    private var earliestRecordDateFormatted: String? {
        guard let date = earliestDates.values.min() else {
            return nil
        }
        return dateFormatter.string(from: date)
    }


    var body: some View {
        NavigationStack {
            mainContent
                .background(Color(.systemBackground))
                .navigationTitle("USER_STUDY_WECOME")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    settingsButton
                }
                .sheet(isPresented: $isPresentingSettings) {
                    AccessGuarded(.userStudy) {
                        SettingsView()
                    }
                }
                .fullScreenCover(isPresented: $isPresentingStudy) {
                    AccessGuarded(.userStudy) {
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
                    await fhirInterpretationModule.updateSchemas()
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
            Text("USER_STUDY_WELCOME_TITLE")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("LLM_ON_FHIR")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }

    private var studyDescription: some View {
        Text("USER_STUDY_WELCOME_DESCRIPTION")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 32)
    }

    @ViewBuilder private var recordsStartDateView: some View {
        if let earliestRecordDateFormatted {
            Button {
                isPresentingEarliestHealthRecords = true
            } label: {
                Text("HEALTH_RECORDS_SINCE: \(earliestRecordDateFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                    .underline()
            }
            .opacity(standard.waitingState.isWaiting ? 0 : 1)
            .padding(.bottom, 16)
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 16) {
            startStudyButton
                .padding(.horizontal, 32)
            recordsStartDateView
            approvalBadge
        }
        .padding(.bottom, 24)
    }

    private var startStudyButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                _startStudyButton
                #if swift(>=6.2)
                    .buttonStyle(.glassProminent)
                #else
                    .background(Color.accent.opacity(standard.waitingState.isWaiting ? 0.5 : 1))
                    .cornerRadius(16)
                    .buttonStyle(.borderedProminent)
                #endif
            } else {
                _startStudyButton
                    .background(Color.accent.opacity(standard.waitingState.isWaiting ? 0.5 : 1))
                    .cornerRadius(16)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var _startStudyButton: some View {
        Button {
            interpreter.startNewConversation()
            isPresentingStudy = true
        } label: {
            HStack(spacing: 8) {
                if standard.waitingState.isWaiting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .controlSize(.regular)
                }
                Text(standard.waitingState.isWaiting ? "LOADING_HEALTH_RECORDS" : "START_SESSION")
            }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
            .controlSize(.extraLarge)
            .buttonBorderShape(.capsule)
            .disabled(standard.waitingState.isWaiting)
            .animation(.default, value: standard.waitingState.isWaiting)
    }

    private var approvalBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.secondary)
                .accessibilityLabel(Text("Checkmark"))
            Text("USER_STUDY_APPROVAL_BADGE_TEXT")
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
        
        guard let apiKey = UserStudyConfig.shared.apiKey else {
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


extension AccessGuardIdentifier where AccessGuard == CodeAccessGuard {
    /// A unique identifier for user study access control.
    /// Used to protect and manage access to user study related features and views.
    static let userStudy: Self = .passcode("UserStudyIdentifier")
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
            instruction: "Ask a clarifying question about one of the diagnoses received in the summary.",
            questions: [
                .init(
                    text: "How effective is this feature for interpreting and evaluating your baby’s medical information?",
                    type: .scale(responseOptions: effectivenessScale)
                )
            ]
        ),
        .init(
            id: 3,
            instruction: "Ask a question about feeding your baby, such as timing, amounts, or methods.",
            questions: [
                .init(
                    text: "How effective was the LLM in helping you understand how to feed your baby?",
                    type: .scale(responseOptions: effectivenessScale)
                )
            ]
        ),
        .init(
            id: 4,
            instruction: "Ask a question about your baby’s follow-up appointments, medications, or technologies.",
            questions: [
                .init(
                    text: "How effective was this response in helping you understand your baby’s care?",
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
            // swiftlint:disable:next line_length
            instruction: "Please feel free to ask any other questions you have about your child’s discharge or transition to home; for example, vaccinations or sleeping.",
            questions: [
                .init(
                    text: "I found the responses easy to understand and at an appropriate reading level.",
                    type: .scale(responseOptions: balancedEaseScale)
                ),
                .init(
                    text: "Using this tool would help me take better care of my child.",
                    type: .scale(responseOptions: comparisonScale)
                ),
                .init(
                    text: "Compared to other sources of health information (e.g., websites, doctors), how do you rate the LLM's responses?",
                    type: .scale(responseOptions: comparisonScale)
                ),
                .init(
                    text: "Learning this tool was easy for me.",
                    type: .scale(responseOptions: balancedEaseScale)
                ),
                .init(
                    text: "I find it easy to get the tool to do what I want it to do.",
                    type: .scale(responseOptions: balancedEaseScale)
                ),
                .init(
                    text: "My interaction with the tool was clear and understandable.",
                    type: .scale(responseOptions: clarityScale)
                ),
                .init(
                    text: "On a scale of 0-10, how likely are you to recommend this tool to a friend or colleague?",
                    type: .netPromoterScore(range: 0...10)
                )
            ]
        )
    ]
}
