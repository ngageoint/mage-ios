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
        default: return false
        }
    }
    
    // MARK: - Obj-C compatible initializer (matches old selector exactly)
    @objc(initWithNavigationController:andDelegate:andScheme:context:)
    public init(navigationController: UINavigationController,
                andDelegate delegate: AuthenticationDelegate?,
                andScheme scheme: AnyObject? = nil,
                context: NSManagedObjectContext? = nil) {
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
            NSLog("[Auth] No base URL; cannot start login.")
            return
        }
        
        MageServer.server(url: url,
                          success: { [weak self] mageServer in
            guard let self else { return }
            Task { @MainActor in
                self.server = mageServer
                self.showLoginView(for: mageServer)
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
    @objc public func createAccount() {
        let signup = SignupHost()
        nav?.pushViewController(signup, animated: false)
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
@MainActor
extension AuthFlowCoordinator: LoginDelegate, IDPCoordinatorDelegate {
    
    @objc public func changeServerURL() {
        authenticationDelegate?.changeServerUrl()
    }
    
    // EXACT selector: loginWithParameters:withAuthenticationStrategy:complete:
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
        
        log.debug("Auth start (strategy=\(authenticationStrategy, privacy: .public))")
        
        auth.login(withParameters: params) { [weak self] status, error in
            Task { @MainActor in
                self?.log.debug("Auth finished (status=\(String(describing: status), privacy: .public))")
                complete(status, error)
                
                if let self, self.isSuccess(status) {
                    self.authenticationDelegate?.authenticationSuccessful()
                }
            }
        }
    }
    
    // EXACT selector: signinForStrategy:
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
        let idp = IDPCoordinatorSwiftUI(
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
        let strategy = (strategyParameter?["identifier"] as? String) ?? (strategyParameter?["type"] as? String) ?? "idp"
        
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
