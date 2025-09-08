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
    
    public func beginSignup() async {
        print("\n--------------------1-------------------------")
        print("beginSignup() called")
        print("----------------------1-----------------------\n")
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        // fetch captcha, then show sheet
        do {
            let res = try await auth.fetchSignupCaptcha(username: username, backgroundHex: "#FFFFFF")
            captchaImageBase64 = res.imageBase64
            captchaToken = res.token
            showCaptcha = true
            print("\n-------------------2--------------------------")
            print("captcha: \(res.imageBase64)")
            print("token: \(res.token)")
            print("---------------------2------------------------\n")
        } catch {
            print("\n-------------------3--------------------------")
            print("Error: \(error.localizedDescription)")
            print("---------------------3------------------------\n")
            
            errorMessage = "Could not fetch CAPTCHA. \(error.localizedDescription)"
            showCaptcha = false
        }
    }
    
    public func completeSignup() async {
        guard let token = captchaToken else { errorMessage = "Missing CAPTCHA token"; return }
        isSubmitting = true
        do {
            let req = SignupRequest(displayName: displayName, username: username, email: email, password: password, confirmPassword: confirmPassword)
            _ = try await auth.submitSignup(req, captchaText: captchaText, token: token)
    } catch let err as AuthError {
        switch err {
        case .invalidInput(let msg), .server(let msg): errorMessage = msg
        case .unauthorized: errorMessage = "Unauthorized. Check your credentials."
        case .rateLimited: errorMessage = "Too many attempts. Please wait and try again."
        case .network: errorMessage = "Network error. Check your connection and retry."
        }
    } catch {
        errorMessage = "Unexpected error. Please try again."
    }
    
    isSubmitting = false
    showCaptcha = false
    
}

    // TODO: Brent - need to change to use the rules set by the server
    public var isFormValid: Bool {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard email.contains("@"), email.contains(".") else { return false }
        guard password.count >= 8 else { return false }
        guard password == confirmPassword else { return false }
        return true
    }
}
