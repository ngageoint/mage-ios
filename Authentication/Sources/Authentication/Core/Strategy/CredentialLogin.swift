//
//  CredentialLogin.swift
//  Authentication
//
//  Created by Brent Michalski on 9/21/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Helper for username/password logins (Local/LDAP/IdP).
/// Performs the HTTP call, maps (status, data, headers) -> AuthError -> (AuthenticationStatus, message),
/// then invokes the provided completion on success/failure.

enum CredentialLogin {
    static func perform(
        url: URL,
        username: String,
        password: String,
        unauthorizedMessage: String,
        timeout: TimeInterval = 30,
        complete: @escaping (AuthenticationStatus, String?) -> Void
    ) {
        Task {
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
                    complete(.success, nil)
                }
            } catch {
                complete(.error, error.localizedDescription)
            }
        }
    }
}
