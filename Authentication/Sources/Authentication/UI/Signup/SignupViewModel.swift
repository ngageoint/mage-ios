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
    @Published public var displayName = ""
    @Published public var username = ""
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    
    @Published public var isSubmitting = false
    @Published public var errorMessage: String?
    @Published public var didSucceed = false
    
    private let auth: AuthService
    private let sessionStore: SessionStore
    
    public init(auth: AuthService, sessionStore: SessionStore) {
        self.auth = auth
        self.sessionStore = sessionStore
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
    
    public func submit() async {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let req = SignupRequest(displayName: displayName, username: username, email: email, password: password, confirmPassword: confirmPassword)
            let session = try await auth.signup(req)
            await sessionStore.set(session)
            didSucceed = true
        } catch let err as AuthError {
            switch err {
            case .invalidInput(let msg), .server(let msg): errorMessage = msg
            case .unauthorized: errorMessage = "Unauthorized. Check your credentials."
            case .rateLimited: errorMessage = "Too many attempts. Please wait and try again."
            case .network: errorMessage = "Network error, Check your connection and retry."
            }
        } catch {
            errorMessage = "Unexpected error. Please try again."
        }
        isSubmitting = false
    }
}


