//
//  TokenExchanger.swift
//  MAGE
//
//  Created by Brent Michalski on 10/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

@MainActor
enum TokenExchanger {
    struct ExchangeError: Error, CustomStringConvertible {
        let description: String
    }
    
    /// Exchange the sign-in token for the real API token @ /auth/token
    static func exchange(signinToken: String, strategy: String) async throws -> String {
        guard let base = MageServer.baseURL() else {
            throw ExchangeError(description: "Missing baseURL")
        }
        
        // Build URL: <base>/auth/token
        let url = base.appendingPathComponent("auth/token")
        
        // Build JSON body { uid, strategy, appVersion }
        let uid: String = DeviceUUID.retrieveDeviceUUID()?.uuidString
        ?? UIDevice.current.identifierForVendor?.uuidString
        ?? "unknown"
        
        let appVersion = UserUtility.appVersionString()
        let body: [String: Any] = [
            "uid": uid,
            "strategy": strategy,
            "appVersion": appVersion
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(signinToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else {
            throw ExchangeError(description: "No HTTP response")
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? "<no body>"
            throw ExchangeError(description: "Exchange failed \(http.statusCode): \(snippet)")
        }
        
        // Parse { "token": "<api token>" }
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = obj as? [String: Any],
              let apiToken = (json["token"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiToken.isEmpty
        else {
            throw ExchangeError(description: "Missing token in /auth/token response")
        }

        // Save new API token to the modern store
        await AuthDependencies.shared.sessionStore?.set(AuthSession(token: apiToken))
        
        // Install into legacy AFNetworking stack so /api/events is authenticated
        MageSessionManager.shared()?.setToken(apiToken)
        StoredPassword.persistToken(toKeyChain: apiToken)
        UserDefaults.standard.set("server", forKey: "loginType")
        
        print("[TokenExchanger] API token installed (len=\(apiToken.count))")
        return apiToken
    }
}
