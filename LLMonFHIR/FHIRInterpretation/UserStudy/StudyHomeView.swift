//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import class ModelsR4.QuestionnaireResponse
import SpeziFoundation
import SpeziHealthKit
import SwiftUI


struct StudyHomeView: View {
    @LocalPreference(.resourceLimit) private var resourceLimit
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(HealthKit.self) private var healthKit
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @Environment(FHIRMultipleResourceInterpreter.self) private var interpreter
    @Environment(FHIRResourceSummarizer.self) private var resourceSummarizer
    @Environment(FirebaseUpload.self) private var uploader: FirebaseUpload?
    @WaitingState private var waitingState
    
    @State private var inProgressStudy: InProgressStudy?
    
    @State private var isPresentingQuestionnaire = false
    @State private var questionnaireResponse: QuestionnaireResponse?
    
    @State private var isPresentingEarliestHealthRecords = false
    @State private var isPresentingQRCodeScanner = false
    
    private var earliestDates: [String: Date] {
        interpreter.fhirStore.earliestDates(limit: resourceLimit)
    }
    private var oldestHealthRecordTimestamp: Date? {
        earliestDates.values.min()
    }
    /// Whether the currently enabled study has an initial questionnaire, and the user still needs to fill that out.
    private var isMissingPreChatQuestionnaire: Bool {
        (try? inProgressStudy?.study.initialQuestionnaire(from: .main)) != nil && questionnaireResponse == nil
    }
    
    var body: some View {
        @Bindable var fhirInterpretationModule = fhirInterpretationModule
        NavigationStack { // swiftlint:disable:this closure_body_length
            mainContent
                .background(Color(.systemBackground))
                .navigationTitle("USER_STUDY_WECOME")
                .navigationBarTitleDisplayMode(.inline)
                #if targetEnvironment(simulator)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        // Maybe instead show a button that directly brings up the ResourceSelection sheet?
                        // (most of the other settings won't be taken into account in study mode...)
                        SettingsButton()
                    }
                }
                #endif
                .sheet(isPresented: $isPresentingEarliestHealthRecords) {
                    EarliestHealthRecordsView(dataSource: earliestDates)
                        .presentationDetents([.medium, .large])
                }
                .qrCodeScanningSheet(isPresented: $isPresentingQRCodeScanner) { payload in
                    guard inProgressStudy == nil else {
                        return .stopScanning
                    }
                    do {
                        let scanResult = try StudyQRCodeHandler.processQRCode(payload: payload)
                        isPresentingQRCodeScanner = false
                        inProgressStudy = .init(
                            study: scanResult.study,
                            config: scanResult.studyConfig,
                            userInfo: scanResult.userInfo
                        )
                        return .stopScanning
                    } catch {
                        print("Failed to start study: \(error)")
                        return .continueScanning
                    }
                }
                .fullScreenCover(isPresented: $isPresentingQuestionnaire) {
                    if let inProgressStudy {
                        QuestionnaireSheet(study: inProgressStudy.study, response: $questionnaireResponse)
                    } else {
                        ContentUnavailableView("Study not selected", systemImage: "document.badge.gearshape")
                    }
                }
                .fullScreenCover(item: $fhirInterpretationModule.currentStudy) { inProgressStudy in
                    UserStudyChatView(model: .init(
                        inProgressStudy: inProgressStudy,
                        initialQuestionnaireResponse: questionnaireResponse,
                        interpreter: interpreter,
                        resourceSummarizer: resourceSummarizer,
                        uploader: uploader
                    ))
                }
                .task {
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
            Text(inProgressStudy?.study.title ?? "LLM on FHIR")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    private var studyDescription: some View {
        let text: LocalizedStringResource = (inProgressStudy?.study.explainer).map { "\($0)" } ?? "Scan a QR Code to Participate in a Study"
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
            if let inProgressStudy {
                if isMissingPreChatQuestionnaire {
                    isPresentingQuestionnaire = true
                    return
                }
                // the HealthKit permissions should already have been granted via the onboarding, but we re-request them here, just in case,
                // to make sure everything is in a proper state when the study gets launched.
                try await healthKit.askForAuthorization()
                fhirInterpretationModule.currentStudy = inProgressStudy
                await fhirInterpretationModule.updateSchemas(forceImmediateUpdate: true)
                interpreter.startNewConversation(using: inProgressStudy.study.interpretMultipleResourcesPrompt)
            } else {
                isPresentingQRCodeScanner = true
            }
        } label: {
            if waitingState.isWaiting {
                Text("LOADING_HEALTH_RECORDS")
            } else if inProgressStudy != nil {
                if isMissingPreChatQuestionnaire {
                    Text("Start Questionnaire")
                } else {
                    Text("START_SESSION")
                }
            } else {
                Label("Scan QR Code", systemImage: "qrcode.viewfinder")
            }
        }
    }
    
    init(study: Study, config: StudyConfig, userInfo: [String: String]) {
        _inProgressStudy = .init(initialValue: InProgressStudy(study: study, config: config, userInfo: userInfo))
    }
    
    init() {
        _inProgressStudy = .init(initialValue: nil)
    }
}
