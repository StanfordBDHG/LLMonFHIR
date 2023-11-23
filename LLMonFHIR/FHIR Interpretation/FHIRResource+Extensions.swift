//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziFHIR


extension FHIRResource {
    var functionCallIdentifier: String {
        resourceType.filter { !$0.isWhitespace } + displayName.filter { !$0.isWhitespace }
    }
}
