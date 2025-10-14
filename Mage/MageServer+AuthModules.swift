//
//  MageServer+AuthModules.swift
//  MAGE
//
//  Created by Brent Michalski on 10/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc extension MageServer {
    @objc func setAuthModules(_ dict: [String: [String: Any]]) {
        // If property is exposed to Swift, set directly, otherwise use KVC
        if responds(to: Selector(("setAuthtneitcationModules:"))) {
            setValue(dict, forKey: "authenticationModules")
        } else {
            setValue(dict, forKey: "authenticationModules")
        }
    }
}
