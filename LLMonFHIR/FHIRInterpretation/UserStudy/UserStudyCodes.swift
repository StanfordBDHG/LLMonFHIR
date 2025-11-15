//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi
import SpeziAccessGuard
import SpeziLocalStorage


@MainActor
final class UserStudyCodes: Module, Sendable {
    @Dependency(LocalStorage.self) private var localStorage
    
    private let allValidCodes = UserStudyConfig.shared.userStudyPasscodes
    
    func validate(_ code: String) -> CodeAccessGuard.ValidationResult {
        guard allValidCodes.contains(code) else {
            return .invalid
        }
        let usedCodes = (try? localStorage.load(.usedStudyCodes)) ?? []
        if usedCodes.contains(code) {
            return .invalid
        } else {
            try? localStorage.store(usedCodes.union(CollectionOfOne(code)), for: .usedStudyCodes)
            return .valid
        }
    }
}


extension LocalStorageKeys {
    fileprivate static let usedStudyCodes = LocalStorageKey<Set<String>>(
        "edu.stanford.LLMonFHIR.usedStudyCodes",
        setting: .unencrypted(excludeFromBackup: true)
    )
}
