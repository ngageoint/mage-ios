//
//  SignupViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

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
    
    private var captchaToken: String?
    
    // MARK: - Dependencies
    private let deps: AuthDependencies
    
    public init(deps: AuthDependencies) {
        self.deps = deps
    }
    
    // MARK: - Validation
    public var isFormValid: Bool {
        guard !displayName.isBlank,
              !username.isBlank,
              email.isPlausibleEmail,
              password.count >= 8,
              password == confirmPassword
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
    
    public func refreshCaptcha() async {
        guard !username.isBlank else { return }
        errorMessage = nil
        isSubmitting = true
        captchaText = ""
        
        do {
            let captcha = try await deps.requireAuthService.fetchSignupCaptcha(username: username, backgroundHex: "FFFFFF")
            captchaToken = captcha.token
            captchaHTML = CaptchaWebView.html(fromBase64Image: captcha.imageBase64)
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
            
            let session = try await deps.requireAuthService.submitSignup(req, captchaText: captchaText, token: token)
            await deps.requireSessionStore.set(session)
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
