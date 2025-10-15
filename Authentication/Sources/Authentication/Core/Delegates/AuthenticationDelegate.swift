//
//  AuthenticationDelegate.swift
//  Authentication
//
//  Created by Brent Michalski on 9/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol AuthenticationDelegate: NSObjectProtocol {
    func authenticationSuccessful()
    func couldNotAuthenticate()
    func changeServerURL()
}
