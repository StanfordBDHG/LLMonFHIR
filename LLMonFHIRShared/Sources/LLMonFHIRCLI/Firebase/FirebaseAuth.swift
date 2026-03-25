//
// This source file is part of the Stanford LLMonFHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation

actor FirebaseAuth {
    let config: FirebaseConfig
    
    private var cachedToken: String?
    private var tokenExpiry: Date = .distantPast
    
    init(config: FirebaseConfig) {
        self.config = config
    }

    func anonymouslySignIn() async throws -> String {
        if let token = cachedToken, tokenExpiry > Date.now.addingTimeInterval(300) {
            return token
        }
        let (token, expiresIn) = try await fetchAnonymousToken()
        cachedToken = token
        tokenExpiry = Date.now.addingTimeInterval(TimeInterval(expiresIn))
        return token
    }

    private func fetchAnonymousToken() async throws -> (token: String, expiresIn: Int) {
        let urlString: String
        if let address = config.authEmulatorAddress {
            urlString = "http://\(address)/identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(config.apiKey)"
        } else {
            urlString = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(config.apiKey)"
        }
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
