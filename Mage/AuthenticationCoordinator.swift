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
@MainActor
public final class AuthFlowCoordinator: NSObject {
    
    // Keep these weak so we don't create retain cycles with UIKit
    public weak var nav: UINavigationController?
    public weak var delegate: AnyObject?                 // Should conform to AuthDelegates
    public weak var scheme: AnyObject?
    public weak var context: NSManagedObjectContext?
    
    // Make public so other modules (MAGE target) can read it if needed
    public private(set) var server: MageServer?
    
    // MARK: - Obj-C compatible initializer (matches old selector exactly)
    // TODO: SettingsTableViewController.m and others call this selector (currently)
    @objc(initWithNavigationController:andDelegate:andScheme:context:)
    public init(navigationController: UINavigationController,
                andDelegate delegate: AnyObject?,
                andScheme scheme: AnyObject? = nil,
                context: NSManagedObjectContext? = nil) {
        self.nav = navigationController
        self.delegate = delegate
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
        
        // Note: MageServer.server calls back on a background queue sometimes
        MageServer.server(withUrl: url) { [weak self] server in
            guard let self else { return }
            
            Task { @MainActor in
                self.server = server
                self.showLoginView(for: server)
            }
        } failure: { error in
            NSLog("[Auth] Failed to contact server: \(error.localizedDescription)")
        }
    }
    
    // Old: -start:
    @objc(start:)
    public func start(_ mageServer: MageServer) {
        self.server = mageServer
        showLoginView(for: mageServer)
    }
    
    // Old: -createAccount
    @objc public func createAccount() {
        let signupVC = SignupHostObjC.make()
        nav?.pushViewController(signupVC, animated: false)
    }
    
    // MARK: - Helpers
    
    private func showLoginView(for server: MageServer) {
        guard let nav = nav else { return }
        
        // We must pass a value conforming to AuthDelegates
        guard let authDelegates = delegate as? AuthDelegates else {
            assertionFailure("AuthFlowCoordinator: delegate must conform to AuthDelegates")
            return
        }
        
        // Use the Obj-C-compatible convenience init we exposed
        let vc = LoginHostViewController(
            mageServer: server,
            andDelegate: authDelegates,
            andScheme: scheme
        )
        nav.pushViewController(vc, animated: false)
    }
}
