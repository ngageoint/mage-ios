//
//  AuthError.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthError: Error, Equatable {
    case invalidCredentials     // 401/403 or server says "bad username/password"
    case accountDisabled        // Server indicates disabled/locked
    case network(underlying: Error)
    case server(status: Int)    // 5xx, unexpected 4xx
    case malformedResponse      // parsing error
    case configuration          // missing url info
    case cancelled              // user cancelled / task cancelled
}

public extension AuthError {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
            (.accountDisabled, .accountDisabled),
            (.malformedResponse, .malformedResponse),
            (.configuration, .configuration),
            (.cancelled, .cancelled):
            return true
            
        case let (.server(a), .server(b)):
            return a == b
            
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
