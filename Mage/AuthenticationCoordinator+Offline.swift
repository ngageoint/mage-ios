//
//  AuthenticationCoordinator+Offline.swift
//  MAGE
//
//  Created by Brent Michalski on 3/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@MainActor
extension AuthFlowCoordinator {
    
    /// Objective-C compatible signature (keeps old selector: `workOffline:complete:`)
    @objc(workOffline:complete:)
    public func workOffline(parameters: NSDictionary,
                            completion: @escaping (AuthenticationStatus, String?) -> Void) {

        // Pull the offline module off the current server
        guard let modules = server?.authenticationModules as? [String: Any],
              let offline = modules["offline"] as? AuthenticationProtocol
        else {
            completion(.unableToAuthenticate, "Offline authentication is not available.")
            return
        }
        
        // Bridge params to swift dictionary
        let params = (parameters as? [String: Any]) ?? [:]
        
        // Call the Authentication module API
        offline.login(withParameters: params) { authenticationStatus, errorString in
            switch authenticationStatus {
            case .success:
                completion(.success, nil)
                
            case .unableToAuthenticate:
                completion(.unableToAuthenticate, "Could not log in offline.")
                
            case .registrationSuccess:
                completion(.registrationSuccess, nil)
                
            case .accountCreationSuccess, .error:
                completion(authenticationStatus, errorString)
                
            @unknown default:
                completion(authenticationStatus, errorString)
            }
        }
    }
}
