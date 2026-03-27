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

    private let auth: FirebaseAuth
    private let firebaseConfig: FirebaseConfig
    private let studyId: String

    init(
        firebaseConfig: FirebaseConfig,
        studyId: String
    ) {
        self.auth = FirebaseAuth(config: firebaseConfig)
        self.firebaseConfig = firebaseConfig
        self.studyId = studyId
    }
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable @concurrent (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let maxBodySize = 7 * 1024 * 1024 // 7 MB
        dispatchPrecondition(condition: .notOnQueue(.main))
        guard let data = try await body?.data(upTo: maxBodySize),
              let input = String(bytes: data, encoding: .utf8) else {
            throw MiddlewareError(description: "Missing Body")
        }
        let stream = try await streamFirebaseFunctionCall(
            name: "chat",
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

    private func streamFirebaseFunctionCall(
        name: String,
        queryItems: [String: String],
        body: String,
    ) async throws -> AsyncThrowingStream<HTTPBody.ByteChunk, any Swift.Error> {
        var components =
            URLComponents(string: name, encodingInvalidCharacters: false) ?? URLComponents()
        let nameItems = components.queryItems ?? []
        let nameKeys = Set(nameItems.map(\.name))
        let additionalItems =
            queryItems
            .filter { !nameKeys.contains($0.key) }
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = nameItems + additionalItems
        let queryString = components.percentEncodedQuery ?? ""
        let callableName = if queryString.isEmpty {
            name
        } else {
            "\(components.percentEncodedPath)?\(queryString)"
        }
        let functionURL = try self.functionURL(for: callableName)
        let idToken = try await auth.anonymouslySignIn()
        var urlRequest = URLRequest(url: functionURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: ["data": body])
        return makeResponseStream(for: urlRequest)
    }

    private func functionURL(for name: String) throws -> URL {
        let urlString: String
        if let address = firebaseConfig.functionsEmulatorAddress {
            urlString = "http://\(address)/\(firebaseConfig.projectID)/\(firebaseConfig.region)/\(name)"
        } else {
            urlString = "https://\(firebaseConfig.region)-\(firebaseConfig.projectID).cloudfunctions.net/\(name)"
        }
        guard let url = URL(string: urlString) else {
            throw MiddlewareError(description: "Could not build function URL for '\(name)'")
        }
        return url
    }
    
    private func makeResponseStream(for urlRequest: URLRequest) -> AsyncThrowingStream<HTTPBody.ByteChunk, any Swift.Error> {
        AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
            Task { [urlRequest] in
                do {
                    let (bytes, httpResponse) = try await URLSession.shared.bytes(
                        for: urlRequest
                    )
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
        }
    }
}

extension HTTPBody {
    fileprivate func data(upTo maxSize: Int) async throws -> some Collection<UInt8> {
        try await ArraySlice(collecting: self, upTo: maxSize)
    }
}
