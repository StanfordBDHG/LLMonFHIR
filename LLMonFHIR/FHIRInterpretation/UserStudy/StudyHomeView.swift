//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import os.log
import SpeziFHIR
import SpeziFoundation
import SpeziKeychainStorage
import SpeziLLMOpenAI
import SwiftUI


struct StudyHomeView: View {
    @LocalPreference(.resourceLimit) private var resourceLimit
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @Environment(FHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(FHIRResourceSummary.self) private var resourceSummary
    @Environment(KeychainStorage.self) private var keychainStorage
    @Environment(LLMOpenAIPlatform.self) private var platform
    @WaitingState private var waitingState
    
    @State private var study: Study?
    @State private var isPresentingEarliestHealthRecords = false
    @State private var isPresentingQRCodeScanner = false
    
    private var earliestDates: [String: Date] {
        interpreter.fhirStore.earliestDates(limit: resourceLimit)
    }
    private var oldestHealthRecordTimestamp: Date? {
        earliestDates.values.min()
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
                        study = try StudyQRCodeHandler.processQRCode(payload: payload)
                        isPresentingQRCodeScanner = false
                        return .stopScanning
                    } catch {
                        print("Failed to start study: \(error)")
                        return .continueScanning
                    }
                }
                .fullScreenCover(item: $fhirInterpretationModule.currentStudy) { study in
                    UserStudyChatView(
                        study: study,
                        interpreter: interpreter,
                        resourceSummary: resourceSummary
                    )
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
        let (title, subtitle) = { () -> (LocalizedStringResource, LocalizedStringResource?) in
            if let study {
                ("\(study.title)", "LLM_ON_FHIR")
            } else {
                ("LLM_ON_FHIR", nil)
            }
        }()
        return VStack(spacing: 8) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
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
            approvalBadge
        }
        .padding(.bottom, 24)
    }
    
    private var primaryActionButton: some View {
        PrimaryActionButton {
            if let study {
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
                Text("START_SESSION")
            } else {
                Label("Scan QR Code", systemImage: "qrcode.viewfinder")
            }
        }
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
    
    init(study: Study?) {
        _study = .init(initialValue: study)
    }
    
    /// Persists the OpenAI token of the user study in the keychain, if no other token already exists.
    private func persistUserStudyOpenApiToken() {
        guard let study else {
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
