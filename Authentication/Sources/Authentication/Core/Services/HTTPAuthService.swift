//
//  HTTPAuthService.swift
//  Authentication
//
//  Created by Brent Michalski on 10/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

public final class HTTPAuthService: AuthService {
    private let baseURL: URL
    public let session: URLSession
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        print("HTTPAuthService init baseURL =", baseURL.absoluteString)
    }
    
    // MARK: - CAPTCHA
    
    public func fetchSignupCaptcha(username: String, backgroundHex: String) async throws -> SignupCaptcha {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.path = (comps.path.isEmpty ? "" : comps.path) + "/api/users/signups"        // TODO: Validate correct path
        guard let url = comps.url else { throw URLError(.badURL) }
        
        let body: [String: Any] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "background": backgroundHex
        ]
        
        let (status, data, _) = try await postJSON(url: url, body: body)
        guard (200...299).contains(status) else {
            throw URLError(.badServerResponse)
        }
        
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        
        let token = (json["token"] as? String)
        let image = (json["captcha"] as? String)
            ?? (json["imageBase64"] as? String)
        
        guard let t = token, let b64 = image, !t.isEmpty, !b64.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        
        return SignupCaptcha(token: t, imageBase64: b64)
    }
    
    // MARK: Signup
    
    public func submitSignup(_ req: SignupRequest, captchaText: String, token: String) async throws -> AuthSession {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.path = (comps.path.isEmpty ? "" : comps.path) + "/api/users/signups/verifications"  // TODO: VERIFY PATH
        guard let url = comps.url else { throw URLError(.badURL) }
        
        var body = req.parameters
        body["captchaText"] = captchaText
        
        let (status, data, _) = try await postJSON(url: url, body: body, headers: ["Authorization": "Bearer \(token)"])
        guard (200...299).contains(status) else {
            throw URLError(.badServerResponse)
        }
        
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard let jwt = json["token"] as? String else { throw URLError(.cannotParseResponse) }
        return AuthSession(token: jwt)
    }
    
    // MARK: - Change Password
    
    // TODO: VERIFY PATHS
    public func changePassword(_ req: ChangePasswordRequest) async throws {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.path = (comps.path.isEmpty ? "" : comps.path) + "/api/users/change-password"  // TODO: VERIFY PATH
        guard let url = comps.url else { throw URLError(.badURL) }
        
        let body: [String: Any] = [
            "currentPassword": req.currentPassword,
            "newPassword": req.newPassword,
            "confirmNewPassword": req.confirmNewPassword
        ]
        
        let (status, _, _) = try await postJSON(url: url, body: body)
        guard (200...299).contains(status) else { throw URLError(.badServerResponse) }
    }
}


private extension HTTPAuthService {
    func getJSON(url: URL, headers: [String: String] = [:], timeout: TimeInterval = 30) async throws -> (status: Int, data: Data, response: HTTPURLResponse) {
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = timeout
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        let (data, resp) = try await session.data(for: req)

        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return(http.statusCode, data, http)
    }
    
    func postJSON(url: URL, body: [String: Any], headers: [String: String] = [:], timeout: TimeInterval = 30) async throws -> (status: Int, data: Data, response: HTTPURLResponse) {
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = timeout
        req.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        req.setValue( "application/json", forHTTPHeaderField: "Accept")
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, resp) = try await session.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (http.statusCode, data, http)
    }
}
