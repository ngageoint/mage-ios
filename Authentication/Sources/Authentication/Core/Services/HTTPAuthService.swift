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
    
    private func absURL(_ path: String) -> URL {
        return URL(string: path, relativeTo: baseURL)!
    }
    
    // MARK: - CAPTCHA
    
    public func fetchSignupCaptcha(username: String, backgroundHex: String) async throws -> SignupCaptcha {
        // POST {base}/api/users/signups
        let url = try apiURL("api/users/signups")
        
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
    
    public func submitSignup(_ request: SignupRequest, captchaText: String, token: String) async throws -> SignupVerificationResponse {
        // /api/users/signups/verifications  (POST with Bearer <token>)
        let url = absURL("/api/users/signups/verifications")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload = SignupVerifyPayload(
            displayName: request.displayName,
            username: request.username,
            email: request.email,
            password: request.password,
            confirmPassword: request.confirmPassword,
            captcha: captchaText
        )
        
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(payload)
        
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        guard (200...299).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            
            throw NSError(
                domain: NSURLErrorDomain,
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey:
                           "Signup verification failed (\(http.statusCode)) \(url.absoluteString)\n\(snippet)"]
            )
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SignupVerificationResponse.self, from: data)
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



private struct SignupVerifyPayload: Encodable {
    let displayName: String
    let username: String
    let email: String
    let password: String
    let confirmPassword: String
    let captcha: String
    
    enum CodingKeys: String, CodingKey {
        case displayName
        case username
        case email
        case password
        case confirmPassword
        case captcha
        case passwordConfirm
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(confirmPassword, forKey: .confirmPassword)
        try container.encode(confirmPassword, forKey: .passwordConfirm)
        try container.encode(captcha, forKey: .captcha)
    }
}
