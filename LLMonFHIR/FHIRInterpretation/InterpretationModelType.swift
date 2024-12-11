//
//  Untitled.swift
//  LLMonFHIR
//
//  Created by Leon Nissen on 11/18/24.
//

import struct OpenAI.Model
import enum SpeziLLMLocal.LLMLocalModel

public enum InterpretationModelType {
    case openAI(OpenAI.Model)
    case local(LLMLocalModel)
}
