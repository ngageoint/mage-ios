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
    }
    
    // MARK: - URL helpers
    
    /// Build a URL by appending path segments to the baseURL, safely handling slashes
    private func makeURL(segments: [String]) -> URL {
        segments.reduce(baseURL) { $0.appendingPathComponent($1) }
    }
    
    // MARK: - CAPTCHA
    
    public func fetchSignupCaptcha(username: String, backgroundHex: String) async throws -> SignupCaptcha {
        // POST {base}/api/users/signups
        let url = makeURL(segments: ["api", "users", "signups"])
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: String] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "background": backgroundHex
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        guard (200...299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            
            throw NSError(
                domain: NSURLErrorDomain,
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey:
                            "CAPTCHA request failed (\(http.statusCode)) \(url.absoluteString)\n\(snippet)"]
            )
        }
        
        let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
        let token = (obj["token"] as? String) ?? (obj["captchaToken"] as? String) ?? ""
        let b64 = (obj["captcha"] as? String) ?? ""
        
        return SignupCaptcha(token: token, imageBase64: b64)
    }
    
    // MARK: Signup
    
    public func submitSignup(_ request: SignupRequest,
                             captchaText: String,
                             token: String) async throws -> SignupVerificationResponse {
        // /api/users/signups/verifications  (POST with Bearer <token>)
        let url = makeURL(segments: ["api", "users", "signups", "verifications"])
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "displayName": request.displayName,
            "username": request.username,
            "email": request.email,
            "password": request.password,
            "passwordconfirm": request.confirmPassword,
            "captchaText": captchaText,
            "phone": ""
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        guard (200...299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            
            throw NSError(
                domain: NSURLErrorDomain,
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Signup verification failed (\(http.statusCode)) \(url.absoluteString)\n\(snippet)"]
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SignupVerificationResponse.self, from: data)
    }
    
    // MARK: - Change Password
    
    // TODO: VERIFY PATHS
    public func changePassword(_ request: ChangePasswordRequest) async throws {
        let url = makeURL(segments: ["api", "users", "change-password"])
        
        let body: [String: Any] = [
            "currentPassword": request.currentPassword,
            "newPassword": request.newPassword,
            "confirmNewPassword": request.confirmNewPassword
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

