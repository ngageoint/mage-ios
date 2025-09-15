//
//  AuthenticationStatus.swift
//  MAGE
//
//  Created by Brent Michalski on 9/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public enum AuthenticationStatus: Int {
    case success                // -> AuthenticationStatusSuccess
    case error                  // -> AuthenticationStatusError
    case unableToAuthenticate   // -> AuthenticationStatusUnableToAuthenticate
    case registrationSuccess    // -> AuthenticationStatusRegistrationSuccess
    case accountCreationSuccess // -> AuthenticationStatusAccountCreationSuccess
}

