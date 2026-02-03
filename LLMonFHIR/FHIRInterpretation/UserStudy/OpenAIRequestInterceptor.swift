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
import LLMonFHIRShared
import OpenAPIRuntime
import Spezi


@Observable
final class OpenAIRequestInterceptor: Module, EnvironmentAccessible, ClientMiddleware, @unchecked Sendable {
    private struct Error: Swift.Error {
        let message: String // periphery:ignore - API
        init(_ message: String) {
            self.message = message
        }
    }
    
    @ObservationIgnored @Dependency(FHIRInterpretationModule.self) private var interpretationModule
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable @concurrent (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let maxBodySize = 7 * 1024 * 1024 // 7 MB
        let endpoint = await MainActor.run {
            interpretationModule.currentStudy?.config.openAIEndpoint ?? .regular
        }
        dispatchPrecondition(condition: .notOnQueue(.main))
        switch endpoint {
        case .regular:
            return try await next(request, body, baseURL)
        case .firebaseFunction(let name):
            guard let data = try await body?.data(upTo: maxBodySize),
                  let input = String(bytes: data, encoding: .utf8) else {
                throw Error("Missing Body")
            }
            let callable = Functions.functions()
                .httpsCallable(name, requestAs: String.self, responseAs: StreamResponse<String, String>.self)
            let res = HTTPResponse(
                status: .ok,
                headerFields: [
                    .contentType: "text/event-stream",
                    .cacheControl: "no-cache",
                    .connection: "keep-alive"
                ]
            )
            let stream = AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
                Task {
                    do {
                        let stream = try callable.stream(input)
                        for try await event in stream {
                            let string = switch event {
                            case .message(let chunk), .result(let chunk):
                                chunk
                            }
                            continuation.yield(HTTPBody.ByteChunk(string.utf8))
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
