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
        self.store = KeychainAuthStore()
    }
    
    public init(parameters: [AnyHashable: Any]?, store: AuthStore) {
        self.store = store
    }
    
    public func canHandleLogin(toURL url: String) -> Bool { store.hasStoredPassword() }
    
    public func login(
        withParameters params: [AnyHashable: Any],
        complete: @escaping (AuthenticationStatus, String?) -> Void) {
        guard store.hasStoredPassword() else {
            return complete(.unableToAuthenticate, "No stored password.")
        }
        
        complete(.success, nil)
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        complete(.success, nil, nil)
    }
}


private struct NullStore: AuthStore {
    init() {}
    func hasStoredPassword() -> Bool { false }
}

