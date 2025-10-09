//
//  CredentialLogin.swift
//  Authentication
//
//  Created by Brent Michalski on 9/21/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
//  Purpose: Single place to perform credential-based sign-in:
//   1) POST JSON (username/password) via HTTP performer
//   2) Map (status, data, headers) → AuthError via HTTPErrorMapper
//   3) Map AuthError → (AuthenticationStatus, message)
//  Modules call this with one line, keeping behavior and messages consistent.
//

import Foundation

/// Helper for username/password logins (Local/LDAP/IdP).
/// Performs the HTTP call, maps (status, data, headers) -> AuthError -> (AuthenticationStatus, message),
/// then invokes the provided completion on success/failure.

enum CredentialLogin {
    
    /// Performs the credential sign-in flow and completes with a user-facing status/message.
    ///
    /// - Parameters:
    ///   - url: Fully-qualified endpoint (e.g., `https://host/auth/local/signin`).
    ///   - username: Finalized username (or email) value.
    ///   - password: Plaintext password from the form.
    ///   - unauthorizedMessage: Module-specific wording for invalid credentials.
    ///   - timeout: Request timeout in seconds (default 30).
    ///   - complete: Completion handler with `(AuthenticationStatus, message?)`.
    static func perform(
        url: URL,
        username: String,
        password: String,
        unauthorizedMessage: String,
        timeout: TimeInterval = 30,
        deliverOnMain: Bool = true,
        complete: @escaping (AuthenticationStatus, String?) -> Void
    ) {
        Task {
            @inline(__always)
            func finish(_ status: AuthenticationStatus, _ message: String?) async {
                
                if deliverOnMain {
                    await MainActor.run { complete(status, message) }
                } else {
                    complete(status, message)
                }
            }
            
            do {
                let (status, data, headers) = try await AuthDependencies.shared.http.postJSONWithHeaders(
                    url: url,
                    headers: [:],
                    body: ["username": username, "password": password],
                    timeout: timeout
                )

                if let authErr = HTTPErrorMapper.map(
                    status: status,
                    headers: headers,
                    bodyData: data
                ) {
                    let (mappedStatus, message) = authErr.toAuthStatusAndMessage(
                        fallbackInvalidCredsMessage: unauthorizedMessage
                    )
                    complete(mappedStatus, message)
                } else {
                    let token: String? = {
                        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                              let json = obj as? [String: Any] else { return nil }
                        
                        if let t = (json["token"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),!t.isEmpty { return t }

                        return nil
                    }()
                    
                    if let t = token {
                        // Save to the NEW store only (Authentication layer responsibility)
                        await AuthDependencies.shared.sessionStore?.set(AuthSession(token: t))
                        print("[CredentialLogin] saved token to SessionStore (len=\(t.count))")
                    } else {
                        print("[CredentialLogin] WARNING: no 'token' in response JSON")
                    }
                    
                    complete(.success, nil)
                }
            } catch {
                complete(.error, error.localizedDescription)
            }
        }
    }
}
