//
//  AuthenticationCoordinator+Offline.swift
//  MAGE
//
//  Created by Brent Michalski on 3/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

@MainActor
extension AuthFlowCoordinator {
    
    /// Objective-C compatible signature (keeps old selector: `workOffline:complete:`)
    @objc(workOffline:complete:)
    public func workOffline(parameters: NSDictionary,
                            completion: @escaping (AuthenticationStatus, String?) -> Void) {

        // Pull the offline module off the current server
        guard let offline = server?.authenticationModules["offline"] else {
            completion(AuthenticationStatus.unableToAuthenticate, "Offline authentication is not available.")
            return
        }
        
        // Bridge params to swift dictionary
        let params = (parameters as? [AnyHashable: Any]) ?? [:]
        
        // Call the Authentication module API
        offline.login(withParameters: params) { authenticationStatus, errorString in
            completion(authenticationStatus, errorString)
        }
    }
}
