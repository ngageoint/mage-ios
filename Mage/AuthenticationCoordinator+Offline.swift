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
        print("🔄 Attempting offline authentication...")

        // Ensure the server has an offline authentication module
        guard let offlineAuthModule = (self.server?.authenticationModules as? [String: AuthenticationProtocol])?["offline"] else {
            print("❌ No offline authentication module available ❌")
            completion(.UNABLE_TO_AUTHENTICATE, "Offline authentication is not available.")
            return
        }

        // Attempt offline login
        offlineAuthModule.login(withParameters: parameters) { authenticationStatus, errorString in
            switch authenticationStatus {
            case .AUTHENTICATION_SUCCESS:
                print("✅ Offline authentication successful ✅")
                completion(.AUTHENTICATION_SUCCESS, nil)
                
            case .REGISTRATION_SUCCESS:
                print("✅ Offline registration successful for user \(parameters["username"] ?? "Unknown") ✅")
                completion(.REGISTRATION_SUCCESS, nil)
                
            case .UNABLE_TO_AUTHENTICATE:
                print("❌ Unable to authenticate offline ❌")
                completion(.UNABLE_TO_AUTHENTICATE, "Could not log in offline.")
                
            default:
                completion(authenticationStatus, errorString)
            }
        }
    }
}
