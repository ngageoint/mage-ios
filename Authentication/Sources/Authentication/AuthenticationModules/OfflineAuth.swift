//
//  OfflineAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class OfflineAuth: AuthenticationModule {
    private let store: AuthStore
    
    public init(parameters: [AnyHashable: Any]?) {
        // If one isn't passed, use default
        self.store = NullAuthStore()
    }
    
    // Convenience init for callers that want to inject a real store.
    public init(parameters: [AnyHashable: Any]?, store: AuthStore) {
        self.store = store
    }
    
    public func canHandleLogin(toURL url: String) -> Bool {
        store.hasStoredPassword()
    }
    
    public func login(withParameters params: [AnyHashable: Any],
                      complete: @escaping (AuthenticationStatus, String?) -> Void) {
        guard store.hasStoredPassword() else {
            complete(.unableToAuthenticate, "No stored password.")
            return
        }
        
        // Your offline verification here if we still need it
        complete(.success, nil)
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        // Offline has nothing to finish.
        complete(.success, nil, nil)
    }
}
