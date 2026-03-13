//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Spezi

// Workaround to make sure types can correctly be found, since `Configuration` is used in multiple dependencies
// and `Spezi.Configuration` is not available, since it will then resolve `Spezi` as the class not the module.
typealias SpeziConfiguration = Configuration
