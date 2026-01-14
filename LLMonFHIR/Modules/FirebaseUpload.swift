//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseStorage
import Foundation
import Spezi
import SpeziFirebaseAccount


@MainActor
final class FirebaseUpload: Module, EnvironmentAccessible, Sendable {
    @Application(\.logger) private var logger
    @Dependency(FirebaseAccountService.self) private var accountService
    
    func configure() {
        Task {
            do {
                try await accountService.signUpAnonymously()
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
