//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import OpenAI


enum LLMFunction {
    static let getResourcesName = "get_resources"
    
    static func getResources(allResourcesFunctionCallIdentifier: [String]) -> ChatFunctionDeclaration {
        ChatFunctionDeclaration(
            name: Self.getResourcesName,
            description: String(localized: "FUNCTION_DESCRIPTION"),
            parameters: JSONSchema(
                type: .object,
                properties: [
                    "resources": .init(
                        type: .string,
                        description: String(localized: "PARAMETER_DESCRIPTION"),
                        enumValues: allResourcesFunctionCallIdentifier
                    )
                ],
                required: [
                    "resources"
                ]
            )
        )
    }
}
