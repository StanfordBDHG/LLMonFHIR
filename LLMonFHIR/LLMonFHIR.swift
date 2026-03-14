//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable all

import LLMonFHIRShared
import Spezi
import SwiftUI
import SpeziQuestionnaire
import SpeziQuestionnaireFHIR
import PencilKit
import class ModelsR4.QuestionnaireResponse


@main
struct LLMonFHIR: App {
    nonisolated static let mode: AppLaunchMode = {
        #if !TEST
        return AppLaunchMode.study(studyId: Study.spineAI.id)
        #endif
        let argv = CommandLine.arguments
        return argv.firstIndex(of: "--mode")
            .flatMap { argv[safe: $0 + 1] }
            .flatMap { AppLaunchMode(rawValue: $0) }
        ?? AppConfigFile.current().appLaunchMode
    }()
    
    @UIApplicationDelegateAdaptor(LLMonFHIRDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                CreateEnrollmentQRCodeSheet()
            } else {
                RootView()
                    .testingSetup()
                    .spezi(appDelegate)
            }
        }
    }
    
    init() {
//        let annot = try! PKDrawing(data: Data(contentsOf: URL(filePath: "/Users/lukas/Desktop/annot2.data")))
//        let Q1 = try! Study.spineAI.initialQuestionnaire(from: .main)!
//        let Q2 = try! SpeziQuestionnaire.Questionnaire(Q1)
//        let responses = QuestionnaireResponses(questionnaire: Q2)
//        responses.responses["7.1"].value.annotatedImageValue = .init(annot)
//        let fhir = try! ModelsR4.QuestionnaireResponse(responses)
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
//        let data = try! encoder.encode(fhir)
//        let string = String(decoding: data, as: UTF8.self)
//        print(string)
//        fatalError()
    }
}
