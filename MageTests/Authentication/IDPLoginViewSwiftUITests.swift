//
//  IDPLoginViewSwiftUITests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import ViewInspector
@testable import MAGE

final class IDPLoginViewSwiftUITests: XCTestCase {
    func testButtonTap_triggersSignin() throws {
        let delegate = MockIDPLoginDelegate()
        let vm = IDPLoginViewModel(strategy: ["identifier": "idp", "name": "IDP"], delegate: delegate)
        let view = IDPLoginViewSwiftUI(viewModel: vm)
        let button = try view.inspect().find(ViewType.Button.self)
        try button.tap()
        XCTAssertEqual(delegate.calledWith?["identifier"] as? String, "idp")
    }


}
