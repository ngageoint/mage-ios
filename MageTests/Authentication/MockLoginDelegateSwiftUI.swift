////
////  MockLoginDelegateSwiftUI.swift
////  MAGETests
////
////  Created by Brent Michalski on 8/5/25.
////  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
////
//
//import XCTest
//@testable import MAGE
//
//class MockLoginDelegateSwiftUI: NSObject, LoginDelegate {
//    var didLogin = false
//    var receivedParameters: [AnyHashable: Any]?
//    var receivedStrategy: String?
//    var completeCalled = false
//    var status: AuthenticationStatus?
//    var error: String?
//    
//    func login(
//        withParameters parameters: [AnyHashable: Any],
//        withAuthenticationStrategy: String,
//        complete: @escaping (AuthenticationStatus, String?) -> Void)
//    {
//        didLogin = true
//        receivedParameters = parameters
//        receivedStrategy = withAuthenticationStrategy
//        completeCalled = false
//        complete(.AUTHENTICATION_SUCCESS, nil)
//        completeCalled = true
//    }
//    
//    func changeServerURL() { }
//    func createAccount() { }
//}
//
