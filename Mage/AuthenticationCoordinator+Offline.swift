//
//  AuthenticationCoordinator+Offline.swift
//  MAGE
//
//  Created by Brent Michalski on 3/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension AuthenticationCoordinator {
    func workOffline(parameters: [String: Any], completion: @escaping (AuthenticationStatus, String?) -> Void) {

        guard let offlineAuthModule = (self.server?.authenticationModules as? [String: AuthenticationProtocol])?["offline"] else {
            completion(.UNABLE_TO_AUTHENTICATE, "Offline authentication is not available.")
            return
        }

        offlineAuthModule.login(withParameters: parameters) { authenticationStatus, errorString in
            switch authenticationStatus {
            case .AUTHENTICATION_SUCCESS:
                completion(.AUTHENTICATION_SUCCESS, nil)
                
            case .REGISTRATION_SUCCESS:
                completion(.REGISTRATION_SUCCESS, nil)
                
            case .UNABLE_TO_AUTHENTICATE:
                completion(.UNABLE_TO_AUTHENTICATE, "Could not log in offline.")
                
            default:
                completion(authenticationStatus, errorString)
            }
        }
    }
}
