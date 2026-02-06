//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import LLMonFHIRShared


final class InProgressStudy: Identifiable {
    let study: Study
    let config: StudyConfig
    /// Additional key-value pairs associated with this particular study session (e.g., a participant id).
    let userInfo: [String: String]
    
    var id: some Hashable {
        ObjectIdentifier(self)
    }
    
    init(study: Study, config: StudyConfig, userInfo: [String: String]) {
        self.study = study
        self.config = config
        self.userInfo = userInfo
    }
}
