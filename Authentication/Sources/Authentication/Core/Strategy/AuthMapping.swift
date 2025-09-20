//
//  AuthMapping.swift
//  Authentication
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@inline(__always)
private func mapErrorToStatus(_ error: AuthError?) -> AuthenticationStatus {
    guard let error else { return .success }
    
    switch error {
    case .invalidCredentials,
            .unauthorized,
            .invalidInput(_),
            .rateLimited(_),
            .accountDisabled:
        return .unableToAuthenticate
        
    case .network(_),
            .server,
            .malformedResponse,
            .configuration,
            .cancelled:
        return .error
        
    }
}

