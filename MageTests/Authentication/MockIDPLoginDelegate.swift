//
//  MockIDPLoginDelegate.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

class MockIDPLoginDelegate: NSObject, IDPLoginDelegate {
    var calledWith: NSDictionary?
    func signinForStrategy(_ strategy: NSDictionary) {
        calledWith = strategy
    }
}
