//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os.log
import SpeziFHIR
import SpeziKeychainStorage
import SpeziLLMOpenAI
import SpeziViews
import SwiftUI


struct SurveyWelcomeView: View {
    @LocalPreference(.resourceLimit) private var resourceLimit

    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @Environment(FHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(FHIRResourceSummary.self) var resourceSummary
    @Environment(KeychainStorage.self) private var keychainStorage
    @Environment(LLMOpenAIPlatform.self) private var platform
    @WaitingState private var waitingState

    var survey: Survey
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
                    SettingsView()
                }
                .fullScreenCover(isPresented: $isPresentingStudy) {
                    UserStudyChatView(
                        survey: survey,
                        interpreter: interpreter,
                        resourceSummary: resourceSummary
                    )
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
            Text(survey.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("LLM_ON_FHIR")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }

    private var studyDescription: some View {
        Text(survey.explainer)
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
            .opacity(waitingState.isWaiting ? 0 : 1)
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
                    .buttonStyle(.glassProminent)
            } else {
                _startStudyButton
                    .background(Color.accent.opacity(waitingState.isWaiting ? 0.5 : 1))
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
                if waitingState.isWaiting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .controlSize(.regular)
                }
                Text(waitingState.isWaiting ? "LOADING_HEALTH_RECORDS" : "START_SESSION")
            }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
            .controlSize(.extraLarge)
            .buttonBorderShape(.capsule)
            .disabled(waitingState.isWaiting)
            .animation(.default, value: waitingState.isWaiting)
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
        do {
            try keychainStorage.store(
                Credentials(
                    username: username,
                    password: survey.openAIAPIKey
                ),
                for: tag
            )
        } catch {
            logger.warning("Could not access keychain to read or store OpenAI API key: \(error)")
        }
    }
}
