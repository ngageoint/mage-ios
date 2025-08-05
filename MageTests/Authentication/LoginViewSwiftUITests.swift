//
//  LoginViewSwiftUITests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import MAGE


final class LoginViewSwiftUITests: XCTestCase {

    func testErrorMessageShown() throws {
        let vm = LoginViewModel(strategy: ["identifier": "local", "strategy": ["title": "Email"]], delegate: nil)
        vm.errorMessage = "Invalid!"
        let view = LoginViewSwiftUI(viewModel: vm)
//        let errorText = try view.inspect().find(text: "Invalid!")  // If you want to be less specific
        let errorText = try view.inspect().find(ViewType.Text.self, where: { try $0.string() == "Invalid!" })
        
        XCTAssertNotNil(errorText)
    }

}
