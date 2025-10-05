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
        // POST {base}/api/users/signups
        let url = try apiURL("api/users/signups")
        
        let payload: [String: Any] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "background": backgroundHex
        ]
        
        let (status, data, http) = try await postJSON(url: url, body: payload)
        
        guard (200...299).contains(status) else {
            // bubble up server details so you can see why it failed
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse,
                          userInfo: [NSLocalizedDescriptionKey: "CAPTCHA request feiled (\(status)) \(http.url?.absoluteString ?? "")\n\(body)"])
        }
        
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = json["token"] as? String,
            let raw = json["captcha"] as? String
        else {
            throw URLError(.cannotParseResponse)
        }
        
        // Accept either raw base64 of full data URL; normalize to base64-only
        let base64: String
        if raw.hasPrefix("data:") {
            base64 = raw.split(separator: ",", maxSplits: 1).last.map(String.init) ?? ""
        } else {
            base64 = raw
        }
        
        return SignupCaptcha(token: token, imageBase64: base64)
    }
    
    func verifySignup(_ payload: [String: Any], bearerToken: String) async throws {
        // POST {base}/api/users/signups/verifications  with Authorization: Bearer <token>
        let url = try apiURL("api/users/signups/verifications")
        let (status, data, http) = try await postJSON(url: url, body: payload, headers: ["Authorization": "Bearer \(bearerToken)"])
        
        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: [NSLocalizedDescriptionKey: "Signup verification failed (\(status)) \(http.url?.absoluteString ?? "")\n\(body)"])
        }
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
    
    func apiURL(_ path: String) throws -> URL {
        guard var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        var path = comps.path
        if !path.hasSuffix("/") { path += "/" }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        comps.path = path + trimmed
        guard let url = comps.url else { throw URLError(.badURL) }
        return url
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
