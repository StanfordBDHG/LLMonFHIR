//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import class ModelsR4.Questionnaire
import class ModelsR4.QuestionnaireResponse
import os.log
import SpeziFHIR
import SpeziFoundation
import SpeziHealthKit
import SpeziKeychainStorage
import SpeziLLMOpenAI
import SwiftUI


struct StudyHomeView: View {
    @LocalPreference(.resourceLimit) private var resourceLimit
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(HealthKit.self) private var healthKit
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @Environment(FHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(FHIRResourceSummary.self) private var resourceSummary
    @Environment(KeychainStorage.self) private var keychainStorage
    @Environment(LLMOpenAIPlatform.self) private var platform
    @Environment(FirebaseUpload.self) private var uploader: FirebaseUpload?
    @WaitingState private var waitingState
    
    @State private var study: Study?
    @State private var studyUserInfo: [String: String]
    
    @State private var isPresentinQuestinnaire = false
    @State private var questinnaireResponse: QuestionnaireResponse?
    
    @State private var isPresentingEarliestHealthRecords = false
    @State private var isPresentingQRCodeScanner = false
    
    private var earliestDates: [String: Date] {
        interpreter.fhirStore.earliestDates(limit: resourceLimit)
    }
    private var oldestHealthRecordTimestamp: Date? {
        earliestDates.values.min()
    }
    private var displayQuestinnaireNext: Bool {
        guard let study else {
            return false
        }
        
        return study.initialQuestinnaire != nil && questinnaireResponse == nil
    }
    
    var body: some View {
        @Bindable var fhirInterpretationModule = fhirInterpretationModule
        NavigationStack { // swiftlint:disable:this closure_body_length
            mainContent
                .background(Color(.systemBackground))
                .navigationTitle("USER_STUDY_WECOME")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    SettingsButton()
                }
                .qrCodeScanningSheet(isPresented: $isPresentingQRCodeScanner) { payload in
                    guard study == nil else {
                        return .stopScanning
                    }
                    do {
                        let scanResult = try StudyQRCodeHandler.processQRCode(payload: payload)
                        isPresentingQRCodeScanner = false
                        study = scanResult.study
                        return .stopScanning
                    } catch {
                        print("Failed to start study: \(error)")
                        return .continueScanning
                    }
                }
                .fullScreenCover(item: $fhirInterpretationModule.currentStudy) { study in
                    UserStudyChatView(
                        study: study,
                        userInfo: studyUserInfo,
                        interpreter: interpreter,
                        resourceSummary: resourceSummary,
                        uploader: uploader
                    )
                }
                .fullScreenCover(isPresented: $isPresentinQuestinnaire) {
                    if let study {
                        QuestinnaireView(study: study, questinnaireResponse: $questinnaireResponse)
                    } else {
                        ContentUnavailableView("Study not selected", systemImage: "document.badge.gearshape")
                    }
                }
                .sheet(isPresented: $isPresentingEarliestHealthRecords) {
                    EarliestHealthRecordsView(
                        dataSource: earliestDates
                    )
                    .presentationDetents([.medium, .large])
                }
                .task {
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
            .accessibilityLabel(Text("Stanford Logo"))
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
            Text(study?.title ?? "LLM on FHIR")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    private var studyDescription: some View {
        let text: LocalizedStringResource = (study?.explainer).map { "\($0)" } ?? "Scan a QR Code to Participate in a Study"
        return Text(text)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 32)
    }

    @ViewBuilder private var recordsStartDateView: some View {
        if let oldestHealthRecordTimestamp {
            Button {
                isPresentingEarliestHealthRecords = true
            } label: {
                Text("HEALTH_RECORDS_SINCE: \(oldestHealthRecordTimestamp, format: .llmOnFhirOldestHealthSample)")
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
            primaryActionButton
                .padding(.horizontal, 32)
                .transforming { view in
                    if #available(iOS 26, *) {
                        view.buttonStyle(.glassProminent)
                    } else {
                        view
                            .background(Color.accent.opacity(waitingState.isWaiting ? 0.5 : 1))
                            .cornerRadius(16)
                            .buttonStyle(.borderedProminent)
                    }
                }
            recordsStartDateView
        }
        .padding(.bottom, 24)
    }
    
    private var primaryActionButton: some View {
        PrimaryActionButton {
            if let study {
                if displayQuestinnaireNext {
                    isPresentinQuestinnaire = true
                    return
                }
                
                // the HealthKit permissions should already have been granted via the onboarding, but we re-request them here, just in case,
                // to make sure everything is in a proper state when the study gets launched.
                try await healthKit.askForAuthorization()
                fhirInterpretationModule.currentStudy = study
                await fhirInterpretationModule.updateSchemas(forceImmediateUpdate: true)
                interpreter.startNewConversation(for: study)
            } else {
                isPresentingQRCodeScanner = true
            }
        } label: {
            if waitingState.isWaiting {
                Text("LOADING_HEALTH_RECORDS")
            } else if study != nil {
                if displayQuestinnaireNext {
                    Text("Start Questinnaire")
                } else {
                    Text("START_SESSION")
                }
            } else {
                Label("Scan QR Code", systemImage: "qrcode.viewfinder")
            }
        }
    }
    
    init(study: Study, userInfo: [String: String]) {
        _study = .init(initialValue: study)
        _studyUserInfo = .init(initialValue: userInfo)
    }
    
    init() {
        _study = .init(initialValue: nil)
        _studyUserInfo = .init(initialValue: [:])
    }
    
    /// Persists the OpenAI token of the user study in the keychain, if no other token already exists.
    private func persistUserStudyOpenApiToken() {
        guard let study, !study.openAIAPIKey.isEmpty else {
            return
        }
        guard case let .keychain(tag, username) = self.platform.configuration.authToken else {
            fatalError("LLMonFHIR relies on an auth token stored in Keychain. Please check your `LLMOpenAIPlatform` configuration.")
        }
        let logger = Logger(subsystem: "edu.stanford.llmonfhir", category: "UserStudyWelcomeView")
        do {
            try keychainStorage.store(
                Credentials(
                    username: username,
                    password: study.openAIAPIKey
                ),
                for: tag
            )
        } catch {
            logger.warning("Could not access keychain to read or store OpenAI API key: \(error)")
        }
    }
}
