//
//  SignupViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import UIKit

@MainActor
public final class SignupViewModel: ObservableObject {
    
    // MARK: - Form state
    @Published public var displayName: String = ""
    @Published public var username: String = ""
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var confirmPassword: String = ""
    
    // MARK: - UI state
    @Published public var isSubmitting = false
    @Published public var errorMessage: String?
    @Published public var didSucceed = false
    
    @Published public var successMessage: String?
    
    // MARK: - CAPTCHA state
    @Published public var showCaptcha: Bool = false
    @Published public var captchaHTML: String = ""
    @Published public var captchaText: String = ""
    @Published var captchaImage: UIImage?
    
    private var captchaToken: String?
    
    // MARK: - Dependencies
    private let deps: AuthDependencies
    private let policy: PasswordPolicy?
    
    public init(deps: AuthDependencies = .shared, policy: PasswordPolicy? = nil) {
        self.deps = deps
        self.policy = policy
    }
    
    // MARK: - Validation
    
    public var passwordViolations: [String] {
        guard let policy else { return [] }
        return policy.validate(password).violations
    }
    
    public var isPasswordPolicySatisfied: Bool {
        if let policy { return policy.validate(password).isValid }
        return password.count >= 8
    }
    
    public var isPasswordConfirmed: Bool {
        confirmPassword == password && !password.isEmpty
    }
    
    public var isFormValid: Bool {
        guard !displayName.isBlank,
              !username.isBlank,
              email.isPlausibleEmail,
              isPasswordPolicySatisfied,
              isPasswordConfirmed
        else { return false }
        return true
    }
    
    public var canRequestCaptcha: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var canSubmit: Bool {
        isFormValid && (captchaToken != nil) && !captchaText.isBlank
    }
    
    public var validationSummary: String {
        var parts: [String] = []
        if displayName.isBlank { parts.append("Display name is required.") }
        if username.isBlank { parts.append("Username is required.") }
        if !email.isPlausibleEmail { parts.append("Enter a valid email address.") }
        
        if !isPasswordPolicySatisfied {
            let rules = passwordViolations
            if rules.isEmpty {
                parts.append("Password does not meet the policy.")
            } else {
                parts.append(contentsOf: rules.map { "Password must \($0)." })
            }
        }
        
        if !isPasswordConfirmed { parts.append("Passwords do not match.") }
        
        return parts.joined(separator: "\n")
    }
    
    // MARK: - Actions
    
    // Step 1: Validate form and fetch a CAPTCHA
    public func beginSignup() async {
        guard isFormValid else { return }
        errorMessage = nil
        isSubmitting = true
        captchaText = ""
        captchaToken = nil
        
        do {
            let bgHex = "FFFFFF"
            let captcha = try await deps.requireAuthService.fetchSignupCaptcha(username: username, backgroundHex: bgHex)
            
            captchaToken = captcha.token
            captchaHTML = Self.buildCaptchaHTML(fromServerValue: captcha.imageBase64)
            showCaptcha = true
        } catch {
            errorMessage = error.userFacingMessage
        }
        
        isSubmitting = false
    }
    
    private func normalizeBase64(_ str: String) -> String {
        // Accept either raw base64 or a full data URL and return raw base64.
        if let comma = str.firstIndex(of: ","), str.hasPrefix("data:") {
            let next = str.index(after: comma)
            return String(str[next...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func refreshCaptcha() async {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        await MainActor.run {
            errorMessage = nil
            isSubmitting = true
            captchaText = ""
            captchaImage = nil
            captchaHTML = ""
        }
        
        do {
            // Fetch from the single, DI-provided AuthService (HTTPAuthService under the hood)
            let captcha = try await deps.requireAuthService.fetchSignupCaptcha(username: username, backgroundHex: "FFFFFF")

            captchaToken = captcha.token
            
            // Build robust HTML from whatever the server sent (data URL or raw base64)
            captchaHTML = Self.buildCaptchaHTML(fromServerValue: captcha.imageBase64)
            
            // 4) (optional) only materialize a UIImage when it isn’t an SVG
            if let raw = Self.extractRawBase64(from: captcha.imageBase64),
               Self.sniffMime(base64: raw) != "image/svg+xml",
               let data = Data(base64Encoded: raw, options: .ignoreUnknownCharacters),
               let img = UIImage(data: data, scale: UIScreen.main.scale) {
                captchaImage = img
            } else {
                captchaImage = nil
            }
            
            errorMessage = nil
        } catch {
            errorMessage = error.userFacingMessage
        }
        
        isSubmitting = false
    }
    
    // MARK: - Helpers
    
    private static func buildCaptchaHTML(fromServerValue value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Case A: already a data URL
        if trimmed.hasPrefix("data:") {
            // If it’s an SVG data-URL, inline the decoded XML (WKWebView is happier with inline SVG)
            if trimmed.lowercased().hasPrefix("data:image/svg+xml;base64,"),
               let raw = extractRawBase64(from: trimmed),
               let data = Data(base64Encoded: raw),
               let svg = String(data: data, encoding: .utf8) {
                return CaptchaWebView.html(fromInlineSVG: svg)
            } else {
                return CaptchaWebView.html(fromDataURL: trimmed)
            }
        }

        // Case B: raw base64
        let mime = sniffMime(base64: trimmed)
        if mime == "image/svg+xml",
           let data = Data(base64Encoded: trimmed),
           let svg = String(data: data, encoding: .utf8) {
            return CaptchaWebView.html(fromInlineSVG: svg)
        } else {
            let chosen = (mime ?? "image/png")
            return CaptchaWebView.html(fromDataURL: "data:\(chosen);base64,\(trimmed)")
        }
    }
    
    private static func extractRawBase64(from value: String) -> String? {
        if value.hasPrefix("data:"), let comma = value.firstIndex(of: ",") {
            return String(value[value.index(after: comma)...])
        }
        return value
    }
    
    private static func sniffMime(base64 raw: String) -> String? {
        if raw.hasPrefix("PHN2Zy") { return "image/svg+xml" }   // "<svg"
        if raw.hasPrefix("iVBORw0KGgo") { return "image/png" }  // PNG
        if raw.hasPrefix("/9j/") { return "image/jpeg" }        // JPEG
        return nil
    }
    
    // Step 2: Submit the form with the captcha text + token
    public func completeSignup() async {
        guard isFormValid else {
            errorMessage = validationSummary
            return
        }
        
        guard let token = captchaToken, !captchaText.isBlank else {
            errorMessage = "Enter the CAPTCHA text to continue."
            return
        }
        
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            let req = SignupRequest(
                displayName: displayName,
                username: username,
                email: email,
                password: password,
                confirmPassword: confirmPassword)
            
            let result = try await deps.requireAuthService.submitSignup(req, captchaText: captchaText, token: token)

            let name = nonEmpty(result.displayName) ?? result.username
            
            successMessage = (result.active == true)
                ?  "Account for \(name) has been created. You can sign in now."
                : "Account for \(name) has been created. An administrator must activate your account before you can sign in."
            
            didSucceed = true
            showCaptcha = false
        } catch {
            errorMessage = error.userFacingMessage
        }
    }
    
    private func nonEmpty(_ s: String?) -> String? {
        guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return t
    }
}


private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var isPlausibleEmail: Bool {
        contains("@") && contains(".")
    }
}

private extension Error {
    var userFacingMessage: String {
        return (self as NSError).localizedDescription
    }
}
