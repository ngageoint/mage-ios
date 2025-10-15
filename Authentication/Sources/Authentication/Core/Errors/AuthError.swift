//
//  AuthError.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthError: Error, Equatable {
    // Login-ish
    case invalidCredentials                 // bad username/password or equivalent
    case unauthorized                       // 401/403 or server says "bad username/password"
    
    // Validation / throttling
    case invalidInput(message: String?)        // 400/422 with field validation errors
    case rateLimited(retryAfterSeconds: Int?)  // 429, optional Retry-After
    
    // Transport / server
    case network(underlying: Error)
    case server(status: Int, message: String?)    // 5xx, unexpected 4xx
    
    // Misc
    case accountDisabled        // Server indicates disabled/locked
    case malformedResponse      // parsing error
    case configuration          // missing url info
    case cancelled              // user cancelled / task cancelled
}

public extension AuthError {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
            (.unauthorized, .unauthorized),
            (.malformedResponse, .malformedResponse),
            (.configuration, .configuration),
            (.cancelled, .cancelled),
            (.accountDisabled, .accountDisabled):
            return true
            
        case let (.invalidInput(a), .invalidInput(b)):
            return a == b
            
        case let (.rateLimited(a), .rateLimited(b)):
            return a == b
            
        case let (.server(sa, ma), .server(sb, mb)):
            return sa == sb && ma == mb
            
        case let (.network(e1), .network(e2)):
            // Compare by domain + code so tests remain stable while allowing different instances
            let n1 = e1 as NSError
            let n2 = e2 as NSError
            return n1.domain == n2.domain && n1.code == n2.code
            
        default:
            return false
        }
    }
}
