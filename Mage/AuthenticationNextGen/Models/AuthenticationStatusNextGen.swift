//
//  AuthenticationStatusNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum AuthenticationStatusNextGen {
    case success
    case error
    case registrationSuccess
    case unableToAuthenticate
    
}

extension AuthenticationStatusNextGen {
    init(legacyStatus: AuthenticationStatus) {
        switch legacyStatus {
        case .AUTHENTICATION_SUCCESS: self = .success
        case .AUTHENTICATION_ERROR: self = .error
        case .REGISTRATION_SUCCESS: self = .registrationSuccess
        case .UNABLE_TO_AUTHENTICATE: self = .unableToAuthenticate
        default: self = .error
        }
    }
}
