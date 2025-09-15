//
//  AuthenticationCoordinator.swift
//  Authentication
//
//  Created by Brent Michalski on 9/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import CoreData
@_exported import Authentication // so Obj-C sees the protocols

// Expose the same Objective-C name the app used before.
@objc(AuthenticationCoordinator)
public final class AuthFlowCoordinator: NSObject {
    
    // NOTE: not private — used by the Offline extension below
    var server: MageServer?
    
    // MARK: - Stored
    private weak var nav: UINavigationController?
    private weak var appDelegate: AuthenticationDelegate?                 // the *external* app-level delegate
    private weak var scheme: AnyObject?
    private weak var context: NSManagedObjectContext?
    
    // MARK: - Obj-C compatible initializer (matches old selector exactly)
    // TODO: SettingsTableViewController.m and others call this selector (currently)
    @objc(initWithNavigationController:andDelegate:andScheme:context:)
    public init(navigationController: UINavigationController,
                andDelegate delegate: AuthenticationDelegate,
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
        
        MageServer.server(url: url, policy: .useCachedIfAvailable, success: { [weak self] server in
            guard let self else { return }
            self.server = server
            DispatchQueue.main.async { self.showLoginView(for: server) }
        }, failure: { error in
            NSLog("[Auth] Failed to contact server: \(error.localizedDescription)")
        })
    }
    
    // Old: -start:
    @objc public func start(_ mageServer: MageServer) {
        server = mageServer
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.showLoginView(for: mageServer)
        }
    }
    
    // MARK: - Helpers
    
    private func showLoginView(for server: MageServer) {
        guard let nav = nav else { return }
        
        // Use the Obj-C-compatible convenience init we exposed
        let vc = LoginHostViewController(
            mageServer: server,
            andDelegate: self,  // <-- self conforms to both protocols
            andScheme: scheme
        )
        nav.pushViewController(vc, animated: false)
    }
}


// MARK: - LoginDelegate + IDPLoginDelegate
extension AuthFlowCoordinator: LoginDelegate, IDPLoginDelegate {

    @objc public func changeServerURL() {
        appDelegate?.changeServerUrl()     // keep legacy behavior
    }

    // Obj-C entry point preserved
    @objc public func createAccount() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let signup = SignupHostObjC.make()
            self.nav?.pushViewController(signup, animated: false)
        }
    }

    // EXACT selector: loginWithParameters:withAuthenticationStrategy:complete:
    @objc(loginWithParameters:withAuthenticationStrategy:complete:)
    public func login(withParameters parameters: NSDictionary,
                      withAuthenticationStrategy authenticationStrategy: String,
                      complete: @escaping (AuthenticationStatus, String?) -> Void) {

        let params = parameters as? [AnyHashable: Any] ?? [:]

        let module =
            (server?.authenticationModules?[authenticationStrategy] as? AuthenticationProtocol) ??
            (server?.authenticationModules?["offline"] as? AuthenticationProtocol)

        guard let auth = module else {
            complete(.unableToAuthenticate, "No authentication module for \(authenticationStrategy).")
            return
        }

        auth.login(withParameters: params) { status, errorString in
            complete(status, errorString)
        }
    }

    // EXACT selector: signinForStrategy:
    @objc(signinForStrategy:)
    public func signinForStrategy(_ strategy: NSDictionary) {
        // unwrap nav safely
        guard let nav = self.nav else { return }
        // pull essentials from the Obj-C dictionary
        guard
            let identifier = strategy["identifier"] as? String,
            let base = MageServer.baseURL()?.absoluteString
        else { return }

        // NOTE: no stray ')' at the end
        let url = "\(base)/auth/\(identifier)/signin"

        // IDPCoordinator expects a non-optional Swift dictionary
        let strategyDict: [AnyHashable: Any] = strategy as? [AnyHashable: Any] ?? [:]

        // IDPCoordinator wants a LoginDelegate, not an IDPLoginDelegate
        let idp = IDPCoordinator(
            viewController: nav,
            url: url,
            strategy: strategyDict,
            delegate: self as LoginDelegate
        )
        idp.start()
    }
}
