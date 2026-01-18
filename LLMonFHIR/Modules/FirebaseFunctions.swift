//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFunctions
import Foundation
import Spezi


final class FirebaseFunctions: Module {
    private let emulatorConfig: (host: String, port: Int)?
    
    init() {
        emulatorConfig = nil
    }
    
    init(emulatorHost host: String, port: Int) {
        self.emulatorConfig = (host, port)
    }
    
    func configure() {
        if let emulatorConfig {
            Functions.functions().useEmulator(withHost: emulatorConfig.host, port: emulatorConfig.port)
        }
    }
}
