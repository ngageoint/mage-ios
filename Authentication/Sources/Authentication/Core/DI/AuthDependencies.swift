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
    
    // MARK: Shared dependencies
    public var sessionStore: SessionStore?
    public var http: HTTPPerforming = HTTPLoginPerformer()
    public var authStore: AuthStore!

    // MARK: Auth service
    public var authService: AuthService? {
        didSet {
            let oldType = oldValue.map { String(describing: type(of: $0)) } ?? "nil"
            let newType = authService.map { String(describing: type(of: $0)) } ?? "nil"
            print("AuthDependencies.authService: \(oldType) -> \(newType)")
        }
    }
    
    /// Optional factory override for tests / previews.
    /// If unset, we build `HTTPAuthService(baseURL:session:)`.
    public var makeAuthService: ((URL, URLSession) -> AuthService)?
    
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

// MARK: - require (and fail fast)
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

// MARK: - Configuration (single place to create/replace the concrete service)
public extension AuthDependencies {
    /// Explicitly (re)configure the auth service with the given base URL.
    /// Use this when the user changes servers or at app bootstrap.
    @discardableResult
    func configureAuthService(baseURL: URL, session: URLSession = .shared) -> AuthService {
        if let make = makeAuthService {
            let svc = make(baseURL, session)
            self.authService = svc
        } else {
            self.authService = HTTPAuthService(baseURL: baseURL, session: session)
        }
        print("Configured AuthService with \(baseURL.absoluteString)")
        return self.authService!
    }
    
    /// Lazily configure the auth service if it is currently nil
    func configureAuthServiceIfNeeded(baseURL: URL?, session: URLSession = .shared) {
        guard authService == nil, let baseURL else { return }
        _ = configureAuthService(baseURL: baseURL, session: session)
    }
    
    /// Wrapper for old call-sites
    /// Prefer `configureAuthServiceIfNeeded(baseURL:)`.
    func ensureAuthService(with baseURL: URL) {
        configureAuthService(baseURL: baseURL)
    }
    
    /// Previous explicit configure API (kept so existing code continues to compile).
    @discardableResult
    func configure(baseURL: URL, session: URLSession = .shared) -> AuthService {
        configureAuthService(baseURL: baseURL, session: session)
    }
    
    /// Reset and create a fresh service for a new server selection.
    @discardableResult
    func resetAuthService(forNewBaseURL baseURL: URL, session: URLSession = .shared) -> AuthService {
        self.authService = nil
        return configureAuthService(baseURL: baseURL, session: session)
    }
}

// MARK: - Preview/Test convenience initializers

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

public extension AuthDependencies {
    func configure(baseURL: URL, session: URLSession = .shared) {
        self.authService = HTTPAuthService(baseURL: baseURL, session: session)
    }
}
