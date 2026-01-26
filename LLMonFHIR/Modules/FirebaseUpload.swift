//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

@preconcurrency import FirebaseAuth
import FirebaseStorage
import Foundation
import LLMonFHIRShared
import Spezi
import SpeziFirebaseAccount


@MainActor
final class FirebaseUpload: Module, EnvironmentAccessible, Sendable {
    @Application(\.logger) private var logger
    @Dependency(FirebaseAccountService.self) private var accountService
    
    func configure() {
        Task {
            do {
                if FeatureFlags.useFirebaseEmulator {
                    logger.notice("User before logout when using Firebase Emulator: \(Auth.auth().currentUser?.uid ?? "n/a")")
                    try? await accountService.logout()
                    logger.notice("User after logout when using Firebase Emulator: \(Auth.auth().currentUser?.uid ?? "n/a")")
                }
                logger.notice("User before anonymous sign up: \(Auth.auth().currentUser?.uid ?? "n/a")")
                try await accountService.signUpAnonymously()
                logger.notice("User after anonymous sign up: \(Auth.auth().currentUser?.uid ?? "n/a")")
            } catch {
                logger.error("Error signing in: \(error)")
            }
        }
    }
    
    func uploadReport(at url: URL, for study: Study) async throws {
        let storageRef = Storage.storage().reference(withPath: "reports/\(study.id)/\(UUID().uuidString).json")
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        _ = try await storageRef.putFileAsync(from: url, metadata: metadata)
    }
}
