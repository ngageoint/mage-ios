//
//  AuthenticationCoordinator.swift
//  Authentication
//
//  Created by Brent Michalski on 9/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import CoreData
@preconcurrency import Authentication // AuthenticationStatus + AuthenticationProtocol

private enum AuthKey {
    static let offline = "offline"
}

// Expose the same Objective-C name the app used before.
@objc(AuthenticationCoordinator)
@MainActor
public final class AuthFlowCoordinator: NSObject {
    
    // MARK: - Stored state
    private weak var nav: UINavigationController?
    private weak var appDelegate: AuthenticationDelegate?                 // the *external* app-level delegate
    private var scheme: AnyObject?
    private weak var context: NSManagedObjectContext?
    public var server: MageServer?
    
    // MARK: - Obj-C compatible initializer (matches old selector exactly)
    @objc(initWithNavigationController:andDelegate:andScheme:context:)
    public init(navigationController: UINavigationController,
                andDelegate delegate: AuthenticationDelegate?,
                andScheme scheme: AnyObject? = nil,
                context: NSManagedObjectContext? = nil) {
        self.nav = navigationController
        self.appDelegate = delegate
        self.scheme = scheme
        self.context = context
        super.init()
    }
    
    // MARK: - Entry points that legacy code calls
    
    // Old: -startLoginOnly
    @objc public func startLoginOnly() {
        guard let url = MageServer.baseURL() else {
            NSLog("[Auth] No base URL; cannot start login.")
            return
        }
        
        MageServer.server(url: url,
                          policy: .useCachedIfAvailable,
                          success: { [weak self] srv in
            guard let self else { return }
            Task { @MainActor in
                self.server = srv
                self.showLoginView(for: srv)
            }
        }, failure: { error in
            NSLog("[Auth] Failed to contact server: \(error.localizedDescription)")
        })
    }
    
    // Old: -start:
    @objc(start:)
    public func start(_ server: MageServer) {
        self.server = server
        showLoginView(for: server)
    }
    
    // Old: -createAccount
    @objc public nonisolated(unsafe) func createAccount() {
        // Protocol is nonisolated; hop to main for UI.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let signup = SignupHost()
            self.nav?.pushViewController(signup, animated: false)
        }
    }
    
    // MARK: - Helpers
    
    private func showLoginView(for server: MageServer) {
        guard let nav = nav else { return }
        
        // Use the Obj-C-compatible convenience init we exposed
        let vc = LoginHostViewController(
            mageServer: server,
            andDelegate: self,  // implemented below
            andScheme: scheme
        )
        nav.pushViewController(vc, animated: false)
    }
}


// MARK: - LoginDelegate + IDPLoginDelegate
extension AuthFlowCoordinator: LoginDelegate, IDPCoordinatorDelegate {
    
    @objc public nonisolated(unsafe) func changeServerURL() {
        Task { @MainActor [weak self] in
            self?.appDelegate?.changeServerUrl()
        }
    }
    
    // EXACT selector: loginWithParameters:withAuthenticationStrategy:complete:
    @objc(loginWithParameters:withAuthenticationStrategy:complete:)
    public nonisolated(unsafe) func login(withParameters parameters: NSDictionary,
                                          withAuthenticationStrategy authenticationStrategy: String,
                                          complete: @escaping (AuthenticationStatus, String?) -> Void) {

        Task { @MainActor [weak self] in
            guard let self, let server = self.server else {
                complete(.unableToAuthenticate, "Internal Error.")
                return
            }
            
            let params = (parameters as? [AnyHashable: Any]) ?? [:]
            
            let modules = server.authenticationModules
            guard let auth = modules[authenticationStrategy] ?? modules[AuthKey.offline] else {
                complete(.unableToAuthenticate, "No authentication module for \(authenticationStrategy).")
                return
            }
            
            auth.login(withParameters: params) { status, error in
                complete(status, error)
            }
        }
    }
    
    // EXACT selector: signinForStrategy:
    @objc(signinForStrategy:)
    public nonisolated(unsafe) func signinForStrategy(_ strategy: NSDictionary) {
        // Extract SENDABLE values first (don’t capture NSDictionary in a @Sendable closure)
        guard
            let identifier = strategy["identifier"] as? String,
            let base = MageServer.baseURL()?.absoluteString
        else { return }

        let urlString = "\(base)/auth/\(identifier)/signin"
        // Minimal payload; IDPCoordinatorSwiftUI expects [String: Any]
        let strategyPayload: [String: Any] = ["identifier": identifier]
        
        // Present UI on main actor
        Task { @MainActor [weak self] in
            guard let self, let nav = self.nav else { return }
            let idp = IDPCoordinatorSwiftUI(
                presenter: nav,
                url: urlString,
                strategy: strategyPayload,
                delegate: self
            )
            
            idp.start()
        }
    }
    
    

    // MARK: - IDPCoordinatorDelegate

    /// Finish the login by calling the existing login path
    public nonisolated(unsafe) func idpCoordinatorDidCompleteSignIn(parameters: [String: Any]) {
        // Derive the strategy key expected by the auth layer.
        let sd = parameters["strategy"] as? [String: Any]
        let strategy = (sd?["identifier"] as? String) ?? (sd?["type"] as? String) ?? "idp"

        // Reuse the same login path.
        self.login(withParameters: parameters as NSDictionary,
                   withAuthenticationStrategy: strategy) { _, _ in }
    }

    /// On IdP sign-up completion, just return the user to the login screen
    public nonisolated(unsafe) func idpCoordinatorDidCompleteSignUp() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let server = self.server else { return }
            self.showLoginView(for: server)
        }
    }
}
