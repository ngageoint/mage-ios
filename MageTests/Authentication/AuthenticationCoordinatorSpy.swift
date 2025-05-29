//
//  AuthenticationCoordinatorSpy.swift
//  MAGE
//
//  Created by Brent Michalski on 3/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import XCTest
@testable import MAGE
import OSLog

class AuthenticationCoordinatorSpy: AuthenticationCoordinator {
    
    private(set) var startCalled = false
    private(set) var startLoginOnlyCalled = false
    private(set) var showLoginViewForServerCalled = false
    private(set) var showLoginViewForServerParam: MageServer?

    override func start(_ mageServer: MageServer?) {
        startCalled = true
        os_log("start(_:) called with server: \(String(describing: mageServer))")
        super.start(mageServer)
    }

    override func startLoginOnly() {
        startLoginOnlyCalled = true
        os_log("startLoginOnly() called")
        super.startLoginOnly()
    }

    /// Properly override `showLoginViewForServer` to track when it's called
    override func showLoginView(for mageServer: MageServer?) {
        showLoginViewForServerCalled = true
        showLoginViewForServerParam = mageServer
        os_log("showLoginViewForServer(_:) was called with \(String(describing: mageServer))")
        super.showLoginView(for: mageServer)
    }
}
