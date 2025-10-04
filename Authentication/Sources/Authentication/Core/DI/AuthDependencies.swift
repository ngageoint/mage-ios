//
//  AuthDependencies.swift
//  MAGE
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation

public final class AuthDependencies {
    public static let shared = AuthDependencies()
    
    public var sessionStore: SessionStore?
    public var http: HTTPPerforming = HTTPLoginPerformer()
    public var authStore: AuthStore!

    public var authService: AuthService? {
        didSet {
            let oldType = oldValue.map { String(describing: type(of: $0)) } ?? "nil"
            let newType = authService.map { String(describing: type(of: $0)) } ?? "nil"
            print("AuthDependencies.authService: \(oldType) -> \(newType)")
        }
    }
    
    public var makeAuthService: ((URL) -> AuthService)?
    
    private init() {}
}

#if DEBUG
extension AuthDependencies {
    public static func resolvedForDebug(
        http: HTTPPerforming = HTTPLoginPerformer()
    ) -> AuthDependencies {
        let authDependencies = AuthDependencies.shared
        authDependencies.http = http
        return authDependencies
    }
}
#endif

public extension AuthDependencies {
    var requireAuthStore: AuthStore {
        guard let store = authStore else { fatalError("AuthDependencies.authStore is not configured") }
        return store
    }
 
    var requireSessionStore: SessionStore {
        guard let store = sessionStore else { fatalError("AuthDependencies.sessionStore is not configured") }
        return store
    }
    
    var requireAuthService: AuthService {
        guard let store = authService else { fatalError("AuthDependencies.authService is not configured") }
        return store
    }
}

// #if DEBUG
public extension AuthDependencies {
    convenience init(
        auth: AuthService,
        sessionStore: SessionStore,
        http: HTTPPerforming = HTTPLoginPerformer(),
        authStore: AuthStore? = nil
    ) {
        self.init()
        self.authService = auth
        self.sessionStore = sessionStore
        self.http = http
        
        if let authStore { self.authStore = authStore }
    }
    
    
    static func preview(auth: AuthService, sessionStore: SessionStore) -> Self {
        Self(auth: auth, sessionStore: sessionStore)
    }
}
// #endif

public extension AuthDependencies {
    func configure(baseURL: URL, session: URLSession = .shared) {
        self.authService = HTTPAuthService(baseURL: baseURL, session: session)
    }
}

public extension AuthDependencies {
    func ensureAuthService(with baseURL: URL) {
        if authService == nil {
            if let make = makeAuthService {
                authService = make(baseURL)
            } else {
                authService = HTTPAuthService(baseURL: baseURL)
            }
            
            print("AuthService configured with:", baseURL.absoluteString, "→", String(describing: type(of: authService!)))
        }
    }
}
