//
//  IDPLoginViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 7/31/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@objcMembers
public class IDPLoginViewModel: NSObject, ObservableObject {
    let strategy: [String: Any]
    weak var delegate: IDPLoginDelegate?
    
    init(strategy: [String: Any], delegate: IDPLoginDelegate?) {
        self.strategy = strategy
        self.delegate = delegate
    }
    
    func signin() {
        print("ZZZ IDPLoginViewModel: Sign in tapped for strategy: \(strategy)")
        delegate?.signinForStrategy(strategy as NSDictionary)
    }
    
    // Properties for button and such, based on strategy
    var displayName: String {
        strategy["name"] as? String ?? "Sign in with IDP"
    }
}

