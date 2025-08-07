//
//  IDPLoginViewModelTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import ViewInspector
@testable import MAGE

final class IDPLoginViewModelTests: XCTestCase {
    func testSignin_callsDelegate() {
        let delegate = MockIDPLoginDelegate()
        let vm = IDPLoginViewModel(strategy: ["identifier": "idp"], delegate: delegate)
        vm.signin()
        XCTAssertEqual(delegate.calledWith?["identifier"] as? String, "idp")
    }

}
