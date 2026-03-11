//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared
import class ModelsR4.Questionnaire
import class ModelsR4.QuestionnaireItem
import class ModelsR4.QuestionnaireResponse
import SpeziFoundation
import SpeziHealthKit
import SwiftUI

// swiftlint:disable file_length

@MainActor
private var viewModel: Any?

struct StudyHomeView: View {
    @LocalPreference(.resourceLimit) private var resourceLimit
    @Environment(LLMonFHIRStandard.self) private var standard
    @Environment(HealthKit.self) private var healthKit
    @Environment(FHIRInterpretationModule.self) private var fhirInterpretationModule
    @Environment(FirebaseUpload.self) private var uploader: FirebaseUpload?
    @WaitingState private var waitingState
    
    @State private var inProgressStudy: InProgressStudy?
    
    @State private var isPresentingQuestionnaire = false
    @State private var questionnaireResponse: QuestionnaireResponse?
    
    @State private var isPresentingEarliestHealthRecords = false
    @State private var isPresentingQRCodeScanner = false
    
    private var earliestDates: [String: Date] {
        fhirInterpretationModule.multipleResourceInterpreter.fhirStore.earliestDates(limit: resourceLimit)
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
                    let model = (viewModel as? UserStudyChatViewModel) ?? UserStudyChatViewModel(
                        inProgressStudy: inProgressStudy,
                        initialQuestionnaireResponse: questionnaireResponse,
                        interpretationModule: fhirInterpretationModule,
                        //                        interpreter: interpreter,
                        //                        resourceSummarizer: resourceSummarizer,
                        uploader: uploader
                    )
                    viewModel = model
                    return UserStudyChatView(model: model)
                }
                .task {
                    let decoder = JSONDecoder()
                    // swiftlint:disable:next force_try force_unwrapping
                    let response = try! decoder.decode(QuestionnaireResponse.self, from: sampleQuestionnaireResponse.data(using: .utf8)!)
                    if let questionnaire = try? inProgressStudy?.study.initialQuestionnaire(from: .main) {
                        for item in response.item ?? [] {
                            if let question = findQuestionWithLinkId(item.linkId.value?.string ?? "", items: questionnaire.item ?? []) {
                                item.text = question.text
                            }
                        }
                    }
                    questionnaireResponse = response
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
            Text(inProgressStudy?.study.title ?? "LLMonFHIR")
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
                if isMissingPreChatQuestionnaire, false {
                    isPresentingQuestionnaire = true
                    return
                }
                // the HealthKit permissions should already have been granted via the onboarding, but we re-request them here, just in case,
                // to make sure everything is in a proper state when the study gets launched.
                try await healthKit.askForAuthorization()
                fhirInterpretationModule.currentStudy = inProgressStudy
                await fhirInterpretationModule.updateSchemas(forceImmediateUpdate: true)
                fhirInterpretationModule.multipleResourceInterpreter.startNewConversation(
                    using: inProgressStudy.study.interpretMultipleResourcesPrompt
                )
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
    
    private func findQuestionWithLinkId(_ linkId: String, items: [QuestionnaireItem]) -> QuestionnaireItem? {
        for item in items {
            if item.linkId.value?.string == linkId {
                return item
            }
            if let foundItem = findQuestionWithLinkId(linkId, items: item.item ?? []) {
                return foundItem
            }
        }
        return nil
    }
}

let sampleQuestionnaireResponse = #"""
{
  "id" : "731DDBB8-FF50-4EAE-8924-20356A6C13B5",
  "resourceType" : "QuestionnaireResponse",
  "status" : "completed",
  "authored" : "2026-03-11T19:14:26.510686039+01:00",
  "item" : [
    {
      "linkId" : "1.1",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "Leg pain or numbness",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/primary-symptom",
            "code" : "leg-pain"
          }
        }
      ]
    },
    {
      "linkId" : "1.2",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "3 to 12 months",
            "code" : "3m-12m",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/symptom-duration"
          }
        }
      ]
    },
    {
      "linkId" : "1.3",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "373067005",
            "system" : "http:\/\/snomed.info\/sct",
            "display" : "No"
          }
        }
      ]
    },
    {
      "linkId" : "1.4",
      "answer" : [
        {
          "valueCoding" : {
            "system" : "http:\/\/snomed.info\/sct",
            "code" : "373067005",
            "display" : "No"
          }
        }
      ]
    },
    {
      "linkId" : "1.5",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "No",
            "code" : "373067005",
            "system" : "http:\/\/snomed.info\/sct"
          }
        }
      ]
    },
    {
      "linkId" : "1.6",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "none",
            "display" : "None of the above",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/neurologic-emergency"
          }
        }
      ]
    },
    {
      "linkId" : "1.7",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "disc",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/structural-context",
            "display" : "Lumbar disc herniation"
          }
        }
      ]
    },
    {
      "linkId" : "1.8",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "No",
            "code" : "373067005",
            "system" : "http:\/\/snomed.info\/sct"
          }
        }
      ]
    },
    {
      "linkId" : "1.9",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "No",
            "system" : "http:\/\/snomed.info\/sct",
            "code" : "373067005"
          }
        }
      ]
    },
    {
      "linkId" : "7.1",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "none",
            "display" : "No pain in this leg",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-pain-loc"
          }
        }
      ]
    },
    {
      "linkId" : "7.2",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "Buttock",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-pain-loc",
            "code" : "buttock"
          }
        }
      ]
    },
    {
      "linkId" : "7.3",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "Yes — same area as pain",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-numbness",
            "code" : "yes-same"
          }
        }
      ]
    },
    {
      "linkId" : "7.4",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "buttock",
            "display" : "Buttock",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-numbness-loc"
          }
        }
      ]
    },
    {
      "linkId" : "7.5",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "Buttock",
            "code" : "buttock",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-numbness-loc"
          }
        }
      ]
    },
    {
      "linkId" : "7.6",
      "answer" : [
        {
          "valueCoding" : {
            "system" : "http:\/\/snomed.info\/sct",
            "code" : "373066001",
            "display" : "Yes"
          }
        }
      ]
    },
    {
      "linkId" : "7.7",
      "answer" : [
        {
          "valueCoding" : {
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-weakness",
            "code" : "none",
            "display" : "No weakness"
          }
        }
      ]
    },
    {
      "linkId" : "7.8",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "heel-walking",
            "display" : "Trouble walking on heels",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-functional-motor"
          }
        }
      ]
    },
    {
      "linkId" : "7.9",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "sudden",
            "display" : "Suddenly",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-onset"
          }
        }
      ]
    },
    {
      "linkId" : "7.10",
      "answer" : [
        {
          "valueCoding" : {
            "display" : "6 weeks – 3 months",
            "code" : "6w-3m",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-duration"
          }
        }
      ]
    },
    {
      "linkId" : "7.11",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "373067005",
            "display" : "No",
            "system" : "http:\/\/snomed.info\/sct"
          }
        }
      ]
    },
    {
      "linkId" : "7.12",
      "answer" : [
        {
          "valueCoding" : {
            "system" : "http:\/\/snomed.info\/sct",
            "display" : "No",
            "code" : "373067005"
          }
        }
      ]
    },
    {
      "linkId" : "7.13",
      "answer" : [
        {
          "valueCoding" : {
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/walking-limitation",
            "code" : "one-mile",
            "display" : "Pain prevents me from walking more than 1 mile"
          }
        }
      ]
    },
    {
      "linkId" : "7.14",
      "answer" : [
        {
          "valueCoding" : {
            "code" : "disc",
            "display" : "Disc herniation",
            "system" : "https:\/\/spineai.stanford.edu\/CodeSystem\/radic-structural-history"
          }
        }
      ]
    }
  ],
  "questionnaire" : "https:\/\/spineai.stanford.edu\/fhir\/Questionnaire\/lumbar-spine-triage"
}
"""#
