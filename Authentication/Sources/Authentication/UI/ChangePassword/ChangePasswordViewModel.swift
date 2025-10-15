//
//  ChangePasswordViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@MainActor
public final class ChangePasswordViewModel: ObservableObject {
    @Published public var currentPassword = ""
    @Published public var newPassword = ""
    @Published public var confirmNewPassword = ""
    @Published public var isSubmitting = false
    @Published public var errorMessage: String?
    @Published public var didSucceed = false
    
    private let authService: AuthService
    
    public init(auth: AuthService) { self.authService = auth }
    
    public convenience init(deps: AuthDependencies) {
        precondition(deps.authService != nil, "AuthDependencies.authService must be injected")
        self.init(auth: deps.authService!)
    }
    
    // TODO: Brent - Need to wire to proper validation code
    public var isFormValid: Bool {
        guard !currentPassword.isBlank else { return false }
        guard newPassword.count >= 8 else { return false }
        guard newPassword == confirmNewPassword else { return false }
        guard newPassword != currentPassword else { return false }
        return true
    }
    
    public func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        
        defer { isSubmitting = false }
        
        do {
            let req = ChangePasswordRequest(currentPassword: currentPassword,
                                            newPassword: newPassword,
                                            confirmNewPassword: confirmNewPassword)
            
            try await authService.changePassword(req)
            didSucceed = true
        } catch let err as AuthError {
            errorMessage = err.uiMessage(flow: .changePassword)
        } catch {
            errorMessage = "Unexpected error. Please try again."
        }
    }
}

private extension String { // CHANGED
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } // CHANGED
}
