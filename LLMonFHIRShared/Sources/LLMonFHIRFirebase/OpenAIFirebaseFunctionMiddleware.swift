//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseCore
import FirebaseFunctions
public import Foundation
public import HTTPTypes
public import LLMonFHIRShared
public import OpenAPIRuntime


/// A `ClientMiddleware` that routes OpenAI API requests through a Firebase callable function.
///
/// When the endpoint config is `.firebaseFunction(name:)`, the middleware forwards the raw OpenAI
/// request body to the named Firebase callable function and streams the response back.
/// When the endpoint is `.regular`, the request passes through unchanged.
///
/// Used by both the iOS app and the CLI (`simulate-session`).
public struct OpenAIFirebaseFunctionMiddleware: ClientMiddleware, Sendable {
    private struct MiddlewareError: Error, CustomStringConvertible {
        let description: String
    }

    private let endpointProvider: @Sendable () async -> StudyConfig.OpenAIEndpointConfig

    /// - Parameter endpointProvider: Called on every request to determine the routing target.
    public init(endpointProvider: @escaping @Sendable () async -> StudyConfig.OpenAIEndpointConfig) {
        self.endpointProvider = endpointProvider
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let maxBodySize = 7 * 1024 * 1024 // 7 MB
        let endpoint = await endpointProvider()
        switch endpoint {
        case .regular:
            return try await next(request, body, baseURL)
        case .firebaseFunction(let name):
            guard let data = try await body?.data(upTo: maxBodySize),
                  let input = String(bytes: data, encoding: .utf8) else {
                throw MiddlewareError(description: "Missing or unreadable request body")
            }
            let callable = Functions.functions()
                .httpsCallable(name, requestAs: String.self, responseAs: StreamResponse<String, String>.self)
            let response = HTTPResponse(
                status: .ok,
                headerFields: [
                    .contentType: "text/event-stream",
                    .cacheControl: "no-cache",
                    .connection: "keep-alive"
                ]
            )
            let responseBody = HTTPBody(
                AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
                    Task {
                        do {
                            let firebaseStream = try callable.stream(input)
                            for try await event in firebaseStream {
                                let chunk = switch event {
                                case .message(let value), .result(let value): value
                                }
                                continuation.yield(HTTPBody.ByteChunk(chunk.utf8))
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                },
                length: .unknown
            )
            return (response, responseBody)
        }
    }
}


// MARK: - Firebase app configuration

/// Configures the default Firebase app from a `GoogleService-Info.plist` file.
///
/// Safe to call multiple times; subsequent calls are ignored once Firebase is already configured.
///
/// - Parameter path: Absolute path to a `GoogleService-Info.plist` file.
public func configureFirebaseApp(contentsOfFile path: String) throws {
    guard FirebaseApp.app() == nil else {
        return
    }
    guard let options = FirebaseOptions(contentsOfFile: path) else {
        throw FirebaseConfigError("Could not parse Firebase configuration at '\(path)'")
    }
    FirebaseApp.configure(options: options)
}


public struct FirebaseConfigError: Error, CustomStringConvertible {
    public let description: String
    public init(_ description: String) { self.description = description }
}


// MARK: - Helpers

extension HTTPBody {
    fileprivate func data(upTo maxSize: Int) async throws -> some Collection<UInt8> {
        try await ArraySlice(collecting: self, upTo: maxSize)
    }
}
