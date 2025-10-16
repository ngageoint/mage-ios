//
//  ErrorMapping.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
@testable import MAGE

/// The contract every auth client must follow when turning HTTP into AuthError.
enum AuthErrorMapping {
    struct Input {
        let status: Int
        let body: [String: Any]?
        
        init(status: Int, data: Data?) {
            self.status = status
            if let data = data,
                let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.body = obj
            } else {
                self.body = nil
            }
        }
    }
    
    static func map(_ input: Input) -> AuthError? {
        switch input.status {
        case 401:
            // Legacy: invalid creds vs offline 401 are surfaced as "invalid credentials"
            return .invalidCredentials
        case 403:
            return .accountDisabled
        case 409:
            // Username conflict during signup, or other resource conflicts
            return .policyViolation(message: input.body?["error"] as? String ?? "Conflict")
        case 422:
            return .policyViolation(message: input.body?["error"] as? String ?? "Validation failed")
        case 500...599:
            return .server(status: input.status, message: input.body?["error"] as? String)
        default:
            return nil // treat as success or handled by caller
        }
    }
}
