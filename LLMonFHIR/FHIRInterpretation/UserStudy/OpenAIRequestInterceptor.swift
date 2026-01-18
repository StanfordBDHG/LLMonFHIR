//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import Foundation
import HTTPTypes
import OpenAPIRuntime


struct OpenAIRequestInterceptor: ClientMiddleware, Sendable {
    private struct Error: Swift.Error {
        let message: String // periphery:ignore - API
        init(_ message: String) {
            self.message = message
        }
    }
    
    private let fhirInterpretationModule: FHIRInterpretationModule
    
    init(_ fhirInterpretationModule: FHIRInterpretationModule) {
        self.fhirInterpretationModule = fhirInterpretationModule
    }
    
    func intercept( // swiftlint:disable:this function_body_length cyclomatic_complexity
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable @concurrent (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let maxBodySize = 7 * 1024 * 1024 // 7 MB
        let endpointConfig = await MainActor.run {
            fhirInterpretationModule.currentStudy?.openAIEndpoint ?? .regular
        }
        switch endpointConfig {
        case .regular:
            return try await next(request, body, baseURL)
        case .firebaseFunction(let name):
            guard let projectId = FirebaseApp.app()?.options.projectID else {
                throw Error("Missing projectId")
            }
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                throw Error("Missing Firebase IDToken")
            }
            guard let data = try await body?.data(upTo: maxBodySize) else {
                throw Error("Missing Body")
            }
            let endpoint: URL = try {
                if let emulatorOrigin = Functions.functions().emulatorOrigin {
                    try URL("\(emulatorOrigin)/\(projectId)/us-central1/\(name)", strategy: .url)
                } else {
                    try URL("https://us-central1-\(projectId).cloudfunctions.net/\(name)", strategy: .url)
                }
            }()
            var req = URLRequest(url: endpoint)
            req.httpMethod = "POST"
            req.httpBody = Data(data)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (bytes, response) = try await URLSession.shared.bytes(for: req)
            guard let response = response as? HTTPURLResponse else {
                throw Error("Invalid response")
            }
            let status = HTTPResponse.Status(code: response.statusCode)
            var fields = HTTPFields()
            for (key, value) in response.allHeaderFields {
                guard let key = (key as? String).flatMap({ HTTPField.Name($0) }), let value = value as? String else {
                    continue
                }
                fields[key] = value
            }
            let res = HTTPResponse(status: status, headerFields: fields)
            let stream = AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
                Task {
                    do {
                        for try await byte in bytes {
                            continuation.yield([byte])
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
            let body = HTTPBody(stream, length: .unknown)
            return (res, body)
        }
    }
}


extension HTTPBody {
    fileprivate func data(upTo maxSize: Int) async throws -> some Collection<UInt8> {
        try await ArraySlice(collecting: self, upTo: maxSize)
    }
}
