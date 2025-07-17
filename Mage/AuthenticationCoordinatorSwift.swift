//
//  AuthenticationCoordinatorSwift.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@objcMembers
class AuthenticationCoordinatorSwift: NSObject {
    // MARK: - Properties
    private(set) var server: MageServer?
    weak var delegate: AuthenticationDelegate?
    var scheme: AppContainerScheming?
    var context: NSManagedObjectContext?
    
    // MARK: - Initialization
    init(server: MageServer? = nil,
         delegate: AuthenticationDelegate? = nil,
         scheme: AppContainerScheming? = nil,
         context: NSManagedObjectContext? = nil)
    {
        self.server = server
        self.delegate = delegate
        self.scheme = scheme
        self.context = context
        super.init()
    }
    
    // MARK: - Main API (mirrors Objective-C signatures)
    func start(server: MageServer?) {
        self.server = server
        // TODO: Implement flow: Show login view for server (can be SwiftUI in a UIHostingController or UIKit for now)
        
    }
    
    func startLoginOnly() {
        // TODO: Fetch MageServer from source, then call start(server:)
    }
    
    func showLoginView(for server: MageServer?) {
        self.server = server
        // TODO: Present login view (UIKit or SwiftUI)
    }
    
    // MARK: - Signup, Captcha, etc. will go here in next steps
    
    // MARK: - Placeholder for Objective-C Interop (if needed)
    // You can add @objc functions or expose properties as needed for bridging.
}
