//
//  CredentialInput.swift
//  Authentication
//
//  Created by Brent Michalski on 9/22/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
//  Purpose: Normalize username/password form parameters and safely build the login URL
//  for credential-based modules (Local, LDAP, IdP). This keeps parameter parsing and
//  URL joining consistent across modules.
//

import Foundation

/// Typed request value produced from loose `[AnyHashable: Any]` form parameters.
struct CredentialRequest {
    /// Fully-qualified endpoint (e.g., https://server.example.com/auth/local/signin)
    let url: URL
    /// Username field; falls back to `email` if `username` is absent.
    let username: String
    /// Plaintext password from the form. (Transport layer handles TLS.)
    let password: String
}

/// Utilities for building `CredentialRequest` values from form dictionaries.
enum CredentialInput {
    /// Build a `CredentialRequest` from loose form params.
    /// - Parameters:
    ///   - params: Mixed form fields gathered from UI/server (e.g., `username`, `email`, `password`, `serverUrl`).
    ///   - path: Endpoint path (e.g., `"/auth/local/signin"`).
    ///   - defaultBase: Fallback base URL string if `params["serverUrl"]` is not provided.
    /// - Returns: A fully validated `CredentialRequest`, or `nil` if any required value is missing/invalid.

    static func make(
        from params: [AnyHashable: Any],
        path: String,
        defaultBase: String?
    ) -> CredentialRequest? {
        // Resolve base URL string: prefer the per-request value, else fallback.
        let baseString: String? = (params["serverUrl"] as? String) ?? defaultBase
        
        guard
            let base = baseString,
            let endpoint = join(base: base, path: path),
            let username = params.string("username") ?? params.string("email"),
            let password = params.string("password"),
            !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !password.isEmpty
        else {
            return nil
        }
        
        return CredentialRequest(url: endpoint, username: username, password: password)
    }
    
    /// Joins a base URL and path, avoiding double slashes and leading/trailing issues.
    private static func join(base: String, path: String) -> URL? {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty else { return nil }
        
        let noTrail = trimmedBase.hasSuffix("/") ? String(trimmedBase.dropLast()) : trimmedBase
        let noLead  = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(noTrail)/\(noLead)")
    }
}
