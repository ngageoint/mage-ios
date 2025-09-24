//
//  AuthError+UI.swift
//  Authentication
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthFlow {
    case login
    case signup
    case changePassword
    case generic
}

public extension AuthError {
    /// Converts an AuthError into a user-facing string appropriate for the current flow.
    func uiMessage(flow: AuthFlow) -> String {
        switch self {
        case .invalidInput(let message):
            if let message, !message.isEmpty { return message }
            
            switch flow {
            case .signup:           return "Please fix the highlighted fields and try again."
            case .changePassword:   return "Please fix the fields and try again."
            default:                return "Invalid input. Please check and try again."
            }
            
        case .unauthorized, .invalidCredentials:
            switch flow {
            case .changePassword:   return "Current password is incorrect."
            default:                return "Unauthorized. Check your credentials."
            }
            
        case .rateLimited(let seconds):
            if let secs = seconds, secs > 0 { return "Too many requests. Try again in \(secs)s." }
            return "Too many requests. Please try again later."
            
        case .network:
            return "Network error. Check your connection and retry."
            
        case .server(let status, let message):
            return message ?? "Server error (\(status)). Please try again."
            
        case .malformedResponse:
            return "Unexpected server response. Please try again."
            
        case .configuration:
            return "App configuration error. Please contact support."
            
        case .cancelled:
            return "Operation cancelled."
            
        case .accountDisabled:
            return "Your account is disabled or locked. Please contact an administrator."
        }
    }
}
