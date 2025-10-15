//
//  OfflineAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class OfflineAuth: AuthenticationModule {

    // Protocol requires this initializer
    public required init(parameters: [AnyHashable: Any]?) { }
    
    public func canHandleLogin(toURL url: String) -> Bool {
        guard let store = AuthDependencies.shared.authStore else { return false }
        return store.hasStoredPassword()
    }
    
    // NOTE: Offline auth succeeds if a password has been stored previously
    public func login(withParameters params: [AnyHashable: Any],
                      complete: @escaping (AuthenticationStatus, String?) -> Void) {
        
        Task {
            guard let store = AuthDependencies.shared.authStore else {
                complete(.error, "Authentication store is not configured.")
                return
            }
            
            if store.hasStoredPassword() {
                complete(.success, nil)
            } else {
                complete(.unableToAuthenticate, "No stored password.")
            }
        }
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        // Offline has nothing to finish.
        complete(.success, nil, nil)
    }
}
