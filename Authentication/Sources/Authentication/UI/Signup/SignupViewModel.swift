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
            captchaHTML = CaptchaWebView.html(fromBase64Image: captcha.imageBase64)
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
            // 1) Fetch from the single, DI-provided AuthService (HTTPAuthService under the hood)
            let captcha = try await deps.requireAuthService.fetchSignupCaptcha(username: username, backgroundHex: "FFFFFF")
            
            // 2) Build a data URL for the web view so it scales correctly via CSS
            let dataURL = "data:image/png;base64,\(captcha.imageBase64)"
            
            // 3) Update UI
            await MainActor.run {
                captchaToken = captcha.token
                // Use the "fromDataURL:" variant so the image renders at natural size and fills the container.
                captchaHTML = CaptchaWebView.html(fromDataURL: dataURL)
                
            }
            
            let b64 = normalizeBase64(captcha.imageBase64)
            if let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
               let img = UIImage(data: data, scale: UIScreen.main.scale) {
                captchaImage = img
                errorMessage = nil
            } else {
                captchaImage = nil
                errorMessage = nil
            }
        } catch {
            errorMessage = error.userFacingMessage
        }
        
        isSubmitting = false
    }
    
    
    // Step 2: Submit the form with the captcha text + token
    public func completeSignup() async {
        guard let token = captchaToken, !captchaText.isBlank else { return }
        errorMessage = nil
        isSubmitting = true
        
        do {
            let req = SignupRequest(
                displayName: displayName,
                username: username,
                email: email,
                password: password,
                confirmPassword: confirmPassword)
            
            let result = try await deps.requireAuthService.submitSignup(req, captchaText: captchaText, token: token)

            didSucceed = true
            showCaptcha = false
        } catch {
            errorMessage = error.userFacingMessage
        }
        
        isSubmitting = false
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
