//
//  AuthenticationCoordinator.swift
//  Authentication
//
//  Created by Brent Michalski on 9/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import CoreData
import Authentication // AuthenticationStatus + AuthenticationProtocol
import OSLog

private enum AuthKey {
    static let offline = "offline"
}

// Expose the same Objective-C name the app used before.
@objc(AuthenticationCoordinator)
@MainActor
public final class AuthFlowCoordinator: NSObject {
    
    /// If non-nil, tests (or production) can inject a specific service.
    /// `startLoginOnly()` will use this first; otherwise it builds one
    /// from the *current* MageServer.baseURL().
    private let injectedServerInfoService: ServerInfoService?
    
    // MARK: - Stored state
    private weak var nav: UINavigationController?
    private weak var authenticationDelegate: AuthenticationDelegate?  // the *external* app-level delegate
    private var scheme: AnyObject?
    private weak var context: NSManagedObjectContext?
    public var server: MageServer?
    private let log = Logger(subsystem: "MAGE.Auth", category: "AuthFlow")
    
    private func isSuccess(_ status: AuthenticationStatus) -> Bool {
        switch status {
        case .success: return true
        case .registrationSuccess: return true
        case .accountCreationSuccess: return true
        default:
            return false
        }
    }
    
    // MARK: - Obj-C compatible initializer (matches old selector exactly)
    @objc(initWithNavigationController:andDelegate:andScheme:context:)
    public init(navigationController: UINavigationController,
                andDelegate delegate: AuthenticationDelegate?,
                andScheme scheme: AnyObject? = nil,
                context: NSManagedObjectContext? = nil) {
        self.injectedServerInfoService = nil
        self.nav = navigationController
        self.authenticationDelegate = delegate
        self.scheme = scheme
        self.context = context
        super.init()
    }
    
    // Test-friendly initializer
    public init(navigationController: UINavigationController,
                andDelegate delegate: AuthenticationDelegate?,
                andScheme scheme: AnyObject?,
                context: NSManagedObjectContext?,
                serverInfoService: ServerInfoService) {
        self.injectedServerInfoService = serverInfoService
        self.nav = navigationController
        self.authenticationDelegate = delegate
        self.scheme = scheme
        self.context = context
        super.init()
    }
    
    // MARK: - Entry points that legacy code calls
    
    // Old: -startLoginOnly
    @objc public func startLoginOnly() {
        guard let url = MageServer.baseURL() else {
            NSLog("[Auth] startLoginOnly aborted: MageServer.baseURL() == nil")
            return
        }
        
        // Always resolve server info against the *current* base URL.
        // Prefer injected service (tests); otherwise create a fresh one.
        let svc = injectedServerInfoService ?? ServerInfoService(baseURL: url)
        
        // NOTE: don’t touch UI off the main actor, and never force-unwrap
        Task {
            do {
                _ = try await svc.fetchServerModules()
                
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    
                    // minimal: set server and proceed
                    let srv = MageServer(url: url)
                    self.server = srv
                    if let base = MageServer.baseURL() {
                        _ = AuthDependencies.shared.resetAuthService(forNewBaseURL: base)
                    }
                    guard let nav = self.nav else {
                        NSLog("[Auth] startLoginOnly: nav is nil, cannot present login")
                        return
                    }
                    self.showLoginView(for: srv)
                    self.log.debug("[Auth] startLoginOnly: presented LoginHostViewController")
                }
            } catch {
                NSLog("[Auth] Server info fetch failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Old: -start:
    @objc(start:)
    public func start(_ server: MageServer) {
        self.server = server
        if let base = MageServer.baseURL() {
            _ = AuthDependencies.shared.resetAuthService(forNewBaseURL: base)
        }
        showLoginView(for: server)
    }
    
    // Old: -createAccount
    @objc public func createAccount() {
        configureAuthServiceIfNeeded()
        
        let policy = MageServer.localPasswordPolicy
        
        let signup = SignupHost(policy: policy, swiftDeps: AuthDependencies.shared)
        nav?.pushViewController(signup, animated: false)
    }
    
    // MARK: - Helpers
    
    private func showLoginView(for server: MageServer) {
        guard let nav else {
            NSLog("[Auth] showLoginView aborted: nav == nil")
            return
        }
        
        // Use the Obj-C-compatible convenience init we exposed
        let vc = LoginHostViewController(
            mageServer: server,
            andDelegate: self,  // implemented below
            andScheme: scheme
        )
        nav.pushViewController(vc, animated: false)
    }
    
    private func configureAuthServiceIfNeeded() {
        guard let base = MageServer.baseURL() else {
            NSLog("[Auth] Missing MageServer.baseURL(); cannot configure AuthService.")
            return
        }
        
        AuthDependencies.shared.ensureAuthService(with: base)
    }
}


// MARK: - LoginDelegate + IDPLoginDelegate
@MainActor
extension AuthFlowCoordinator: LoginDelegate, IDPCoordinatorDelegate {
    
    @objc public func changeServerURL() {
        authenticationDelegate?.changeServerURL()
    }
    
    @objc(loginWithParameters:withAuthenticationStrategy:complete:)
    public func login(withParameters parameters: NSDictionary,
                      withAuthenticationStrategy authenticationStrategy: String,
                      complete: @escaping (AuthenticationStatus, String?) -> Void) {
        
        guard let server = self.server else {
            complete(.unableToAuthenticate, "Internal Error.")
            return
        }
        
        let params  = (parameters as? [AnyHashable: Any]) ?? [:]
        let modules = server.authenticationModules
        
        guard let auth = modules[authenticationStrategy] ?? modules[AuthKey.offline] else {
            complete(.unableToAuthenticate, "No authentication module for \(authenticationStrategy).")
            return
        }
        
        auth.login(withParameters: params) { [weak self] status, error in
            Task { @MainActor in
                self?.log.debug("-------------------------------------------------------------")
                self?.log.debug("Auth finished (status=\(String(describing: status), privacy: .public))")
                self?.log.debug("-------------------------------------------------------------")
                complete(status, error)
                
                if let self, self.isSuccess(status) {
                    self.authenticationDelegate?.authenticationSuccessful()
                }
            }
        }
    }
    
    @objc(signinForStrategy:)
    public func signinForStrategy(_ strategy: NSDictionary) {
        // Extract SENDABLE values first (don’t capture NSDictionary in a @Sendable closure)
        guard
            let identifier = strategy["identifier"] as? String,
            let base = MageServer.baseURL()?.absoluteString
        else { return }
        
        let urlString = "\(base)/auth/\(identifier)/signin"
        let strategyPayload: [String: Any] = ["identifier": identifier]
        
        // Present UI on main actor
        guard let nav = self.nav else { return }
        let idp = IDPCoordinator(
            presenter: nav,
            url: urlString,
            strategy: strategyPayload,
            delegate: self
        )
        
        idp.start()
    }
    
    // MARK: - IDPCoordinatorDelegate
    
    /// Finish the login by calling the existing login path
    public func idpCoordinatorDidCompleteSignIn(parameters: [String: Any]) {
        // Derive the strategy key expected by the auth layer.
        let strategyParameter = parameters["strategy"] as? [String: Any]
        let strategy = (strategyParameter?["identifier"] as? String) 
            ?? (strategyParameter?["type"] as? String) ?? "idp"
        
        // Reuse the same login path.
        self.login(withParameters: parameters as NSDictionary,
                   withAuthenticationStrategy: strategy) { _, _ in }
    }
    
    /// On IdP sign-up completion, just return the user to the login screen
    public func idpCoordinatorDidCompleteSignUp() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let server = self.server else { return }
            self.showLoginView(for: server)
        }
    }
}

extension AuthFlowCoordinator: DisclaimerDelegate {
    @objc public func disclaimerAgree() {
        UserUtility.singleton.acceptConsent()
        nav?.popToRootViewController(animated: false)
        authenticationDelegate?.authenticationSuccessful()
    }
    
    @objc public func disclaimerDisagree() {
        (UIApplication.shared.delegate as? AppDelegate)?.logout()
    }
}
