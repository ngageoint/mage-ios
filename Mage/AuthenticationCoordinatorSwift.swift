//
//  AuthenticationCoordinatorSwift.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc public protocol AuthenticationCoordinatorDelegate where Self: NSObjectProtocol {
    @objc func authenticationDidSucceed()
    @objc func authenticationDidFail(error: NSError)
}

@objcMembers
class AuthenticationCoordinatorSwift: NSObject {
    
    // MARK: - Properties
    //    weak var delegate: AuthenticationDelegate?
    @objc public private(set) var server: MageServer?
    @objc public weak var delegate: AuthenticationCoordinatorDelegate?
    @objc public var scheme: AppContainerScheming?
    @objc public var context: NSManagedObjectContext?
    @objc public var navigationController: UIViewController?
    
    // MARK: - Initialization
    @objc public init(
        navigationController: UINavigationController,
         delegate: AuthenticationCoordinatorDelegate? = nil,
         scheme: AppContainerScheming? = nil,
         context: NSManagedObjectContext? = nil)
    {
        self.delegate = delegate
        self.scheme = scheme
        self.context = context
        super.init()
    }
    
    // MARK: - Main API (trying to mirror Objective-C signatures)
    @objc func start(_ mageServer: MageServer) {
        self.server = mageServer
        NSLog("XXX [AuthenticationCoordinatorSwift] start: called with server: %@", mageServer)
        
        // TODO: Present your SwiftUI/UIViewController login view here, or trigger your login process.
        // For testing: call authenticationDidSucceed after a short delay to confirm bridge works.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.delegate?.authenticationDidSucceed()
        }
        
        showLoginView(for: mageServer)
        
    }
    
    @objc func startLoginOnly() {
        // TODO: Fetch MageServer from source, then call start(server:)
    }
    
    @objc func showLoginView(for server: MageServer?) {
        self.server = server
        // TODO: Present login view (UIKit or SwiftUI)
    }
    
    // MARK: - Signup, Captcha, etc. will go here in next steps
    
    // MARK: - Placeholder for Objective-C Interop (if needed)
    // You can add @objc functions or expose properties as needed for bridging.
}
