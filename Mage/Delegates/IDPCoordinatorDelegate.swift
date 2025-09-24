//
//  IDPCoordinatorDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@MainActor
protocol IDPCoordinatorDelegate: AnyObject {
    func idpCoordinatorDidCompleteSignIn(parameters: [String: Any])
    func idpCoordinatorDidCompleteSignUp()
}
