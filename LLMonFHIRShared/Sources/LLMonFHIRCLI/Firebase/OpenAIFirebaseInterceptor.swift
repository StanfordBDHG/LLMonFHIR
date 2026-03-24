//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HTTPTypes
import LLMonFHIRShared
import OpenAPIRuntime

struct OpenAIFirebaseInterceptor: ClientMiddleware, Sendable {
    private struct MiddlewareError: Error, CustomStringConvertible {
        let description: String
    }

    private let firebaseConfig: FirebaseConfig
    private let endpointProvider: @Sendable () async -> StudyConfig.OpenAIEndpointConfig

    private static let tokenCache = FirebaseAuth()

    init(
        firebaseConfig: FirebaseConfig,
        endpointProvider: @escaping @Sendable () async -> StudyConfig.OpenAIEndpointConfig
    ) {
        self.firebaseConfig = firebaseConfig
        self.endpointProvider = endpointProvider
    }

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let maxBodySize = 7 * 1024 * 1024  // 7 MB
        let endpoint = await endpointProvider()
        switch endpoint {
        case .regular:
            return try await next(request, body, baseURL)
        case .firebaseFunction(let name):
            do {
                guard let data = try await body?.data(upTo: maxBodySize),
                    let input = String(bytes: data, encoding: .utf8)
                else {
                    throw MiddlewareError(description: "Missing or unreadable request body")
                }
                let response = HTTPResponse(
                    status: .ok,
                    headerFields: [
                        .contentType: "text/event-stream",
                        .cacheControl: "no-cache",
                        .connection: "keep-alive",
                    ]
                )
                let functionURL = try self.functionURL(for: name)
                let idToken = try await Self.tokenCache.token(config: firebaseConfig)
                var urlRequest = URLRequest(url: functionURL)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
                urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: ["data": input])
                let responseBody = HTTPBody(
                    AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
                        Task { [urlRequest] in
                            do {
                                let (bytes, httpResponse) = try await URLSession.shared.bytes(
                                    for: urlRequest)
                                guard let resp = httpResponse as? HTTPURLResponse,
                                    resp.statusCode == 200
                                else {
                                    print(
                                        "Function call failed with status code: \((httpResponse as? HTTPURLResponse)?.statusCode ?? -1)"
                                    )
                                    throw MiddlewareError(description: "Function call failed")
                                }
                                for try await line in bytes.lines {
                                    guard line.hasPrefix("data: "),
                                        let jsonData = String(line.dropFirst(6)).data(using: .utf8),
                                        let json = try? JSONSerialization.jsonObject(with: jsonData)
                                            as? [String: Any],
                                        let chunk = (json["message"] ?? json["result"]) as? String
                                    else { continue }
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
            } catch {
                print("Error in OpenAIFirebaseInterceptor: \(error)")
                throw error
            }
        }
    }

    private func functionURL(for name: String) throws -> URL {
        let urlString: String
        if let address = firebaseConfig.functionsEmulatorAddress {
            urlString = "http://\(address)/\(firebaseConfig.projectID)/us-central1/\(name)"
        } else {
            urlString = "https://us-central1-\(firebaseConfig.projectID).cloudfunctions.net/\(name)"
        }
        guard let url = URL(string: urlString) else {
            throw MiddlewareError(description: "Could not build function URL for '\(name)'")
        }
        return url
    }
}


// MARK: - Helpers

extension HTTPBody {
    fileprivate func data(upTo maxSize: Int) async throws -> some Collection<UInt8> {
        try await ArraySlice(collecting: self, upTo: maxSize)
    }
}
