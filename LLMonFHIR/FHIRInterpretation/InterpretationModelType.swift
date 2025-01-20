//
// This source file is part of the Stanford Spezi project
//
// SPDX-FileCopyrightText: 2024 Stanford University
//
// SPDX-License-Identifier: MIT
//

import struct OpenAI.Model
import enum SpeziLLMLocal.LLMLocalModel

/// A type that represents different kinds of interpretation models that can be used within the application.
/// `InterpretationModelType` provides a way to specify whether the interpretation
/// should be handled by OpenAI's  or local LLM models.
public enum InterpretationModelType {
    /// Represents an OpenAI-provided model.
    /// - Parameter model: The specific OpenAI model to use for interpretation
    case openAI(OpenAI.Model)
    
    /// Represents a locally available LLM model.
    /// - Parameter model: The specific local model to use for interpretation
    case local(LLMLocalModel)
}
