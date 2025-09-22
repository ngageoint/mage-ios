//
//  CredentialInput.swift
//  Authentication
//
//  Created by Brent Michalski on 9/22/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// A single, typed input for credential-based logins.
struct CredentialRequest {
    let url: URL
    let username: String
    let password: String
}

enum CredentialInput {
    /// Build a `CredentialRequest` from loose form params.
    /// - Parameters:
    ///   - params: Form fields from the UI/server.
    ///   - path:   Endpoint path like "/auth/local/signin".
    ///   - defaultBase: Fallback base URL (e.g., `AuthDefaults.baseServerUrl`).
    /// - Returns: A request if all required parts exist; otherwise `nil`.
    
    static func make(
        from params: [AnyHashable: Any],
        path: String,
        defaultBase: String?
    ) -> CredentialRequest? {
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
    
    // Robust join that avoids "//" and supports leading and trailing slashes
    private static func join(base: String, path: String) -> URL? {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty else { return nil }
        
        let noTrail = trimmedBase.hasSuffix("/") ? String(trimmedBase.dropLast()) : trimmedBase
        let noLead  = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(noTrail)/\(noLead)")
    }
}
