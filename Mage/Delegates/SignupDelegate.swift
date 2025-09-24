//
//  SignupDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 9/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc(SignupDelegate)
public protocol SignupDelegate: AnyObject {
    func getCaptcha(_ username: String, completion: @escaping (String) -> Void)
    
    // NSHTTPURLResponse in Obj-C == HTTPURLResponse in Swift
    func signup(withParameters parameters: [String: Any],
                completion: @escaping (HTTPURLResponse?) -> Void)
    
    func signupCanceled()
}
