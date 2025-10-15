////
////  LoginDelegatesDouble.swift
////  MAGETests
////
////  Created by Brent Michalski on 8/26/25.
////  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
////
//
//import Foundation
//@testable import MAGE
//
//final class TestLoginDelegate: NSObject, LoginDelegate, IDPLoginDelegate {
//    struct Call {
//        let params: [AnyHashable: Any]
//        let strategy: String
//    }
//    
//    private(set) var loginCalls: [Call] = []
//    private(set) var idpCalls: [NSDictionary] = []
//    
//    func login(withParameters parameters: [AnyHashable : Any],
//               withAuthenticationStrategy authenticationStrategy: String,
//               complete: @escaping (AuthenticationStatus, String?) -> Void) {
//        loginCalls.append(.init(params: parameters, strategy: authenticationStrategy))
//        complete(.AUTHENTICATION_SUCCESS, nil)
//    }
//    
//    func changeServerURL() {}
//    
//    func createAccount() {}
//    
//    // IDP
//    func signinForStrategy(_ strategy: NSDictionary) {
//        print("ZZZ TestLoginDelegate: Sign in tapped for strategy: \(strategy)")
//        idpCalls.append(strategy)
//    }
//}
