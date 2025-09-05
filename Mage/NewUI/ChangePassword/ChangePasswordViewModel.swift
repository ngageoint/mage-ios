//
//  ChangePasswordViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@MainActor
public final class ChangePasswordViewModel: ObservableObject {
    @Published public var currentPassword = ""
    @Published public var newPassword = ""
    @Published public var confirmNewPassword = ""
    @Published public var isSubmitting = false
    @Published public var errorMessage: String?
    @Published public var didSucceed = false
    
    private let auth: AuthService
    
    public init(auth: AuthService) { self.auth = auth }
    
    // TODO: Brent - Need to wire to proper validation code
    public var isFormValid: Bool {
        guard !currentPassword.isEmpty else { return false }
        guard newPassword.count >= 8 else { return false }
        guard newPassword == confirmNewPassword else { return false }
        guard newPassword != currentPassword else { return false }
        return true
    }
    
    public func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        
        do {
            let req = ChangePasswordRequest(currentPassword: currentPassword,
                                            newPassword: newPassword,
                                            confirmNewPassword: confirmNewPassword)
            
            try await auth.changePassword(req)
            didSucceed = true
        } catch let err as AuthError {
            switch err {
            case .invalidInput(let msg), .server(let msg): errorMessage = msg
            case .unauthorized: errorMessage = "Current password is incorrect"
            case .rateLimited: errorMessage = "Too many requests. Please try again later."
            case .network: errorMessage = "Network error. Check your connection and retry."
            }
        } catch {
            errorMessage = "Unexpected error. Please try again."
        }
        isSubmitting = false
    }
}
