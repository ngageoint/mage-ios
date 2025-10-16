//
//  AuthErrors.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum AuthError: Error, Equatable, LocalizedError {
    case invalidCredentials
    case accountDisabled
    case network(underlying: Error?)
    case server(status: Int, message: String?)
    case decoding(underlying: Error?)
    case policyViolation(message: String)
    case cancelled
    case unimplemented(String = "")
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid username or password."
        case .accountDisabled: return "This account is disabled."
        case .network:            return "Network error. Check your connection."
        case .server(_, let msg): return msg ?? "Server error."
        case .decoding: return "Failed to parse server response."
        case .policyViolation(let m): return m
        case .cancelled: return "Request was cancelled."
        case .unimplemented(let hint):
            return hint.isEmpty ? "Not implemented." : "Not implemented: \(hint)."
        }
    }
}

// MARK: - Equatable (manual because Error? isn't Equatable)
func == (lhs: AuthError, rhs: AuthError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidCredentials, .invalidCredentials),
        (.accountDisabled, .accountDisabled),
        (.cancelled, .cancelled):
        return true
        
        // We intentionally ignore the underlying Error payload for eauality
    case (.network, .network),
        (.decoding, .decoding):
        return true
        
    case let (.server(s1, m1), .server(s2, m2)):
        return s1 == s2 && m1 == m2
        
    case let (.policyViolation(m1), .policyViolation(m2)):
        return m1 == m2
        
    case let (.unimplemented(h1), .unimplemented(h2)):
        return h1 == h2
        
    default:
        return false
    }
}
