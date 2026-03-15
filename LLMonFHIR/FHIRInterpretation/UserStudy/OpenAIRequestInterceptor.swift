//
// This source file is part of the Stanford LLMonFHIR project
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
final class OpenAIRequestInterceptor: Module, EnvironmentAccessible, ClientMiddleware,
    @unchecked Sendable {
    private struct Error: Swift.Error, CustomStringConvertible {
        let description: String
        init(_ description: String) {
            self.description = description
        }
    }

    @ObservationIgnored @Dependency(FHIRInterpretationModule.self) private var interpretationModule

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next:
            @Sendable @concurrent (HTTPRequest, HTTPBody?, URL) async throws -> (
                HTTPResponse, HTTPBody?
            )
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let maxBodySize = 7 * 1024 * 1024  // 7 MB
        let (endpoint, studyId) = await MainActor.run {
            let study = interpretationModule.currentStudy
            return (study?.config.openAIEndpoint ?? .regular, study?.study.id)
        }
        dispatchPrecondition(condition: .notOnQueue(.main))
        switch endpoint {
        case .regular:
            return try await next(request, body, baseURL)
        case .firebaseFunction(let name):
            guard let data = try await body?.data(upTo: maxBodySize),
                let input = String(bytes: data, encoding: .utf8)
            else {
                throw Error("Missing Body")
            }
            let stream = streamFirebaseFunctionCall(
                name: name,
                queryItems: [
                    "ragEnabled": "true",
                    "studyId": studyId
                ].compactMapValues { $0 },
                body: input
            )
            let res = HTTPResponse(
                status: .ok,
                headerFields: [
                    .contentType: "text/event-stream",
                    .cacheControl: "no-cache",
                    .connection: "keep-alive"
                ]
            )
            let body = HTTPBody(stream, length: .unknown)
            return (res, body)
        }
    }

    private func streamFirebaseFunctionCall(
        name: String,
        queryItems: [String: String],
        body: String,
    ) -> AsyncThrowingStream<HTTPBody.ByteChunk, any Swift.Error> {
        var components = URLComponents()
        components.queryItems = queryItems
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        let queryString = components.percentEncodedQuery ?? ""
        let callableName = queryString.isEmpty ? name : "\(name)?\(queryString)"
        let callable = Functions.functions()
            .httpsCallable(
                callableName,
                requestAs: String.self,
                responseAs: StreamResponse<String, String>.self
            )
        return AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
            let task = Task {
                do {
                    let stream = try callable.stream(body)
                    for try await event in stream {
                        try Task.checkCancellation()
                        let string =
                            switch event {
                            case .message(let chunk), .result(let chunk):
                                chunk
                            }
                        continuation.yield(HTTPBody.ByteChunk(string.utf8))
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

extension HTTPBody {
    fileprivate func data(upTo maxSize: Int) async throws -> some Collection<UInt8> {
        try await ArraySlice(collecting: self, upTo: maxSize)
    }
}
