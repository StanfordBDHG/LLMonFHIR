//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable attributes

import ArgumentParser
import CryptoKit
import Foundation
import LLMonFHIRShared
import LLMonFHIRStudyDefinitions


struct ExportConfigFile: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export-config",
        abstract: "Creates a UserStudyConfig.plist file that can be embedded into the app",
        discussion: #"""
            Note: in order to create the sample plist file that is commited to the repo, use the following command:
                swift run LLMonFHIRCLI export-config -f '<emulator>' --allow-empty-api-keys ../LLMonFHIR/Supporting\ Files/UserStudyConfig.plist
            """#
    )
    
    @Option(
        name: [.customShort("l"), .customLong("launchMode")],
        help: "The app's launch mode. Defaults to study and should probably not be customized."
    )
    var launchMode: AppLaunchMode = .study(studyId: nil)
    
    @Option(
        name: [.customShort("f"), .customLong("firebaseConfig")],
        help: "Firebase GoogleService-Info.plist file that should be embedded into the config file"
    )
    var firebaseConfigFilePath: URL?
    
    @Option(
        name: .customLong("studies"),
        help: "The studies that should be included in the config file. Omit to include all studies."
    )
    var includedStudyIds: [String] = Study.allStudies.map(\.id)
    
    @Option(
        name: [.customShort("o"), .customLong("openAIKey")],
        help: "Per-study OpenAI API keys"
    )
    var openAIKeys: [StudyIdIdentified<String>] = []
    
    @Option(
        name: [.customShort("k"), .customLong("encryptionKey")],
        help: "Defines the public_key.pem that should be used to encrypt a study's report files",
    )
    var encryptionKeys: [StudyIdIdentified<URL>] = []
    
    @Option(
        name: [.customShort("e"), .customLong("reportEmail")],
        help: "Defines the email address to which a study's report files should be sent, if the firebase upload is not available.",
    )
    var reportEmails: [StudyIdIdentified<String>] = []
    
    @Option(
        name: [.customShort("s"), .customLong("settingsUnlockCode")],
        help: "Defines each study's settings unlock code, if applicable",
    )
    var settingsUnlockCodes: [StudyIdIdentified<String>] = []
    
    @Option(
        name: [.customLong("studyEndpoint")],
        help: "Each study's OpenAI Endpoint. Defaults to 'regular' if omitted",
    )
    var studyEndpoints: [StudyIdIdentified<StudyConfig.OpenAIEndpointConfig>] = []
    
    // used to generate the default UserStudyConfig.plist file that is commited to the repo.
    @Flag(help: .hidden)
    var allowEmptyAPIKeys = false
    
    @Argument(help: "Output path where the resulting UserStudyConfig.plist file should be stored")
    var outputUrl: URL
    
    
    func run() throws {
        let firebaseConfig: AppConfigFile.FirebaseConfigDictionary? = try {
            guard let firebaseConfigFilePath else {
                return nil
            }
            if firebaseConfigFilePath == URL(argument: "<emulator>") {
                return .emulator
            }
            let data = try Data(contentsOf: firebaseConfigFilePath)
            return try PropertyListDecoder().decode(AppConfigFile.FirebaseConfigDictionary.self, from: data)
        }()
        let config = AppConfigFile(
            launchMode: launchMode,
            studyConfigs: try Study.allStudies.reduce(into: [:]) { configs, study in
                configs[study.id] = StudyConfig(
                    openAIAPIKey: try studyValue(
                        for: study.id,
                        in: openAIKeys,
                        what: "OpenAI API Key",
                        isRequired: !allowEmptyAPIKeys,
                        default: ""
                    ),
                    openAIEndpoint: studyValue(for: study.id, in: studyEndpoints, default: .regular),
                    settingsUnlockCode: studyValue( for: study.id, in: settingsUnlockCodes, default: ""),
                    reportEmail: studyValue( for: study.id, in: reportEmails, default: ""),
                    encryptionKey: try { () -> Curve25519.KeyAgreement.PublicKey? in
                        if let url = studyValue(for: study.id, in: encryptionKeys, default: nil) {
                            try Curve25519.KeyAgreement.PublicKey(contentsOf: url)
                        } else {
                            nil
                        }
                    }()
                )
            },
            firebaseConfig: firebaseConfig
        )
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(config)
        try data.write(to: outputUrl)
    }
    
    
    private func studyValue<V>(
        for studyId: Study.ID,
        in values: [StudyIdIdentified<V>],
        what: String,
        isRequired: Bool,
        default defaultValue: @autoclosure () -> V
    ) throws -> V {
        if let value = values.last(where: { $0.studyId == studyId })?.value {
            return value
        } else if !isRequired {
            return defaultValue()
        } else {
            throw NSError(domain: "edu.stanford.LLMonFHIR.CLI", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Missing \(what) for study '\(studyId)'"
            ])
        }
    }
    
    private func studyValue<V>(
        for studyId: Study.ID,
        in values: [StudyIdIdentified<V>],
        default defaultValue: @autoclosure () -> V
    ) -> V {
        values.last(where: { $0.studyId == studyId })?.value ?? defaultValue()
    }
    
    private func studyValue<V>(
        for studyId: Study.ID,
        in values: [StudyIdIdentified<V>],
        default defaultValue: @autoclosure () -> V?
    ) -> V? {
        values.last(where: { $0.studyId == studyId })?.value ?? defaultValue()
    }
}


// MARK: Utils

extension ExportConfigFile {
    struct StudyIdIdentified<Value: ExpressibleByArgument>: ExpressibleByArgument {
        let studyId: String
        let value: Value
        
        init?(argument: String) {
            guard let idx = argument.firstIndex(of: ":") else {
                return nil
            }
            self.studyId = String(argument[..<idx])
            guard let value = Value(argument: String(argument[argument.index(after: idx)...])) else {
                return nil
            }
            self.value = value
        }
    }
}

extension AppLaunchMode: ExpressibleByArgument {
    public static var allValueStrings: [String] {
        var allOptions = [Self.standalone, .test, .study(studyId: nil)]
        for study in Study.allStudies {
            allOptions.append(.study(studyId: study.id))
        }
        return allOptions.map(\.rawValue)
    }
}


extension URL: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        self = URL(filePath: argument, relativeTo: .currentDirectory())
    }
}

extension StudyConfig.OpenAIEndpointConfig: ExpressibleByArgument {}
