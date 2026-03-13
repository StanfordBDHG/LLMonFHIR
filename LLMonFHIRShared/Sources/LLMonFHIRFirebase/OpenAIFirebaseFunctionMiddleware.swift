//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseAuth
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
    public init(endpointProvider: @escaping @Sendable () async -> StudyConfig.OpenAIEndpointConfig)
    {
        self.endpointProvider = endpointProvider
    }

    // Shared cache so all concurrent sessions share one anonymous token per API key.
    private static let tokenCache = AnonymousTokenCache()

    public func intercept(
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
            #if os(macOS)
                // On macOS CLI tools, keychain-access-groups entitlements require a provisioning
                // profile which SPM executables can't have. Use the REST Identity Toolkit API for
                // anonymous auth and call the function directly over HTTP instead.
                guard let options = FirebaseApp.app()?.options,
                    let apiKey = options.apiKey,
                    let projectId = options.projectID,
                    let functionURL = URL(
                        string: "https://us-central1-\(projectId).cloudfunctions.net/\(name)")
                else {
                    print("Firebase not configured or missing project ID")
                    throw MiddlewareError(
                        description: "Firebase not configured or missing project ID")
                }
                let idToken = try await Self.tokenCache.token(webApiKey: apiKey)
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
            #else
                // On iOS, Firebase Auth has proper keychain entitlements via the app's provisioning profile.
                do {
                    try await Auth.auth().signInAnonymously()
                } catch {
                    print(error)
                }
                let callable = Functions.functions()
                    .httpsCallable(
                        name, requestAs: String.self,
                        responseAs: StreamResponse<String, String>.self)
                let responseBody = HTTPBody(
                    AsyncThrowingStream(HTTPBody.ByteChunk.self) { continuation in
                        Task {
                            do {
                                let firebaseStream = try callable.stream(input)
                                for try await event in firebaseStream {
                                    let chunk =
                                        switch event {
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
            #endif
                        return (response, responseBody)

            } catch {
                print("Error in OpenAIFirebaseFunctionMiddleware: \(error)")
                throw error
            }
        }
    }
}

// MARK: - Anonymous token cache (macOS)

/// Fetches a Firebase anonymous auth token via the Identity Toolkit REST API and caches it
/// until 5 minutes before expiry. Shared across all middleware instances so the app authenticates
/// only once per run regardless of how many concurrent sessions are in flight.
private actor AnonymousTokenCache {
    private var cachedToken: String?
    private var tokenExpiry: Date = .distantPast

    func token(webApiKey: String) async throws -> String {
        if let token = cachedToken, tokenExpiry > Date.now.addingTimeInterval(300) {
            return token
        }
        let (token, expiresIn) = try await fetchAnonymousToken(webApiKey: webApiKey)
        cachedToken = token
        tokenExpiry = Date.now.addingTimeInterval(TimeInterval(expiresIn))
        return token
    }

    private func fetchAnonymousToken(webApiKey: String) async throws -> (token: String, expiresIn: Int) {
        let urlString = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(webApiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["returnSecureToken": true])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AuthError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Anonymous login failed: \(errorMessage)"])
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["idToken"] as? String else {
            throw NSError(domain: "AuthError", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No idToken in response"])
        }
        let expiresIn = (json["expiresIn"] as? String).flatMap(Int.init) ?? 3600
        return (idToken, expiresIn)
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
