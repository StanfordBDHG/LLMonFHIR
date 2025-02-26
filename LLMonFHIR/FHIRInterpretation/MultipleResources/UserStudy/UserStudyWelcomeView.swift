//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziAccessGuard
import SpeziLLMOpenAI
import SwiftUI


struct UserStudyWelcomeView: View {
    @Environment(LLMOpenAITokenSaver.self) private var tokenSaver
    @State private var isPresentingSettings = false
    @State private var isPresentingStudy = false


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
                    AccessGuarded(.userStudyIndentifier) {
                        SettingsView()
                    }
                }
                .fullScreenCover(isPresented: $isPresentingStudy) {
                    AccessGuarded(.userStudyIndentifier) {
                        UserStudyChatView(survey: Survey(.defaultTasks))
                    }
                }
                .onAppear {
                    tokenSaver.token = OpenAIPlistConfiguration.shared.apiKey ?? ""
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

    private var bottomSection: some View {
        VStack(spacing: 16) {
            startStudyButton
                .padding(.horizontal, 32)
            approvalBadge
        }
        .padding(.bottom, 32)
    }

    private var startStudyButton: some View {
        Button(action: { isPresentingStudy = true }) {
            Text("Start Session")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accent)
                .cornerRadius(16)
        }
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
}

private struct OpenAIPlistConfiguration {
    enum ConfigurationError: Error {
        case missingFile
        case invalidFormat
    }

    static let shared: OpenAIPlistConfiguration = {
        do {
            return try loadFromBundle()
        } catch {
            #if DEBUG
            print("OpenAI configuration not available: \(error)")
            #endif
            return OpenAIPlistConfiguration(apiKey: nil)
        }
    }()

    /// The OpenAI API key loaded from the configuration file.
    /// Will be nil if the configuration file is missing or invalid.
    let apiKey: String?

    private static func loadFromBundle() throws -> OpenAIPlistConfiguration {
        guard let url = Bundle.main.url(forResource: "OpenAIConfig", withExtension: "plist") else {
            throw ConfigurationError.missingFile
        }

        let data = try Data(contentsOf: url)
        let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        guard let plist = dict, let apiKey = plist["OpenAI_API_Key"] as? String else {
            throw ConfigurationError.invalidFormat
        }

        return OpenAIPlistConfiguration(apiKey: apiKey)
    }
}


extension AccessGuardConfiguration.Identifier {
    /// A unique identifier for user study access control.
    /// Used to protect and manage access to user study related features and views.
    static var userStudyIndentifier: Self {
        .init("UserStudyIndentifier")
    }
}

extension [SurveyTask] {
    /// Default set of survey tasks used in the user study
    static let defaultTasks: [SurveyTask] = [
        .init(id: 1, questions: [
            .init(
                text: "How clear and understandable was the summary provided by the app?",
                type: .likertScale(range: 1...5)
            )
        ]),
        .init(id: 2, questions: [
            .init(
                text: "How effective is this feature for interpreting and evaluating your medical information?",
                type: .likertScale(range: 1...5)
            )
        ]),
        .init(id: 3, questions: [
            .init(
                text: "How effective are these recommendations in helping you make decisions about your health?",
                type: .likertScale(range: 1...5)
            )
        ]),
        .init(id: 4, questions: [
            .init(
                text: "How effective are these recommendations in helping you make decisions about your health?",
                type: .likertScale(range: 1...5),
                isOptional: true
            ),
            .init(
                text: "What surprised you about the LLMs answer, either positively or negatively?",
                type: .freeText,
                isOptional: true
            )
        ]),
        .init(id: 5, questions: [
            .init(
                text: "Compared to other sources of health information (e.g., websites, doctors), how do you rate the LLM's responses?",
                type: .likertScale(range: 1...5)
            ),
            .init(
                text: "What were the most and least useful features of the LLM? Do you have any suggestions that you would like to share?",
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
        ])
    ]
}
