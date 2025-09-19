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
    @Published public var displayName: String = ""
    @Published public var username: String = ""
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var confirmPassword: String = ""
    
    @Published public var isSubmitting = false
    @Published public var errorMessage: String?
    @Published public var didSucceed = false
    
    @Published public var captchaImageBase64: String?
    @Published public var captchaToken: String?
    @Published public var captchaText: String = ""
    @Published public var showCaptcha: Bool = false
    
    private let auth: AuthService
    private let sessionStore: SessionStore
    
    public init(auth: AuthService, sessionStore: SessionStore) {
        self.auth = auth
        self.sessionStore = sessionStore
    }
    
    public convenience init(deps: AuthDependencies) {
        precondition(deps.authService != nil, "AuthDependencies.authService must be injected")
        precondition(deps.sessionStore != nil, "AuthDependencies.sessionStore must be injected")
        self.init(auth: deps.authService!, sessionStore: deps.sessionStore!)
    }
    
    public func beginSignup() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        // fetch captcha, then show sheet
        do {
            let res = try await auth.fetchSignupCaptcha(username: username, backgroundHex: "#FFFFFF")
            captchaImageBase64 = res.imageBase64
            captchaToken = res.token
            showCaptcha = true
        } catch {
            errorMessage = "Could not fetch CAPTCHA. \(error.localizedDescription)"
            showCaptcha = false
        }
    }
    
    public func completeSignup() async {
        guard let token = captchaToken else { errorMessage = "Missing CAPTCHA token"; return }
        isSubmitting = true
        
        defer {
            isSubmitting = false
            showCaptcha = false
        }
        
        do {
            let req = SignupRequest(displayName: displayName, username: username, email: email, password: password, confirmPassword: confirmPassword)
            _ = try await auth.submitSignup(req, captchaText: captchaText, token: token)
            didSucceed = true
    } catch let err as AuthError {
        errorMessage = err.uiMessage(flow: .signup)
    } catch {
        errorMessage = "Unexpected error. Please try again."
    }
}

    // TODO: Brent - need to change to use the rules set by the server
    public var isFormValid: Bool {
        guard !displayName.isBlank else { return false }
        guard !username.isBlank else { return false }
        guard email.isPlausibleEmail else { return false }
        guard password.count >= 8 else { return false }
        guard password == confirmPassword else { return false }
        return true
    }
}


private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var isPlausibleEmail: Bool {
        contains("@") && contains(".")
    }
}
