//
//  AuthError+Mapping.swift
//  Authentication
//
//  Created by Brent Michalski on 9/21/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public extension AuthError {
    /// Convert an AuthError into user-facing auth status + message.
    /// `fallbackInvalidCredsMessage` lets each module keep its own wording.
    func toAuthStatusAndMessage(fallbackInvalidCredsMessage: String? = nil) -> (AuthenticationStatus, String?) {
        switch self {
        case .unauthorized:
            return (.unableToAuthenticate, fallbackInvalidCredsMessage ?? "Invalid credentials.")
            
        case .invalidCredentials:
            return (.unableToAuthenticate, fallbackInvalidCredsMessage ?? "Invalid credentials.")
            
        case .accountDisabled:
            return (.unableToAuthenticate, "Account disabled.")
            
        case .rateLimited(let retryAfterSeconds):
            let message: String
            if let seconds = retryAfterSeconds, seconds > 0 {
                message = "Too many attempts. Try again in \(seconds)s."
            } else {
                message = "Too many attempts. Try again later."
            }
            return (.error, message)
            
        case .invalidInput(let message):
            return (.error, message ?? "Invalid input.")
            
        case .server(let status, let message):
            return (.error, message ?? "Server error (\(status)).")
            
        case .network(underlying: let underlyingError):
            return (.error, _friendlyURLErrorMessage(from: underlyingError))
            
        case .malformedResponse:
            return (.error, "Malformed server response.")
            
        case .configuration:
            return (.error, "Authentication configuration error. Please contact support.")
            
        case .cancelled:
            return (.error, "Request was cancelled.")
            
        @unknown default:
            return (.error, String(describing: self))
        }
    }
}

private func _friendlyURLErrorMessage(from error: Error) -> String {
    if let urlErr = error as? URLError {
        switch urlErr.code {
        case .notConnectedToInternet: return "No internet connection."
        case .timedOut: return "Request timed out."
        case .cannotFindHost,
                .cannotConnectToHost: return "Couldn't connect to the server."
        case .networkConnectionLost: return "Network connection was lost."
        case .secureConnectionFailed,
                .serverCertificateUntrusted,
                .serverCertificateHasBadDate,
                .serverCertificateHasUnknownRoot,
                .serverCertificateNotYetValid,
                .clientCertificateRejected,
                .clientCertificateRequired:
            return "Secure connection failed."
        default:
            return urlErr.localizedDescription
        }
    }
    return error.localizedDescription
}
