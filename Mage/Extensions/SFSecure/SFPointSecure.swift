//
//  SFPointSecure.swift
//  MAGE

// This is temporary until sf-ios gets published with nssecurecoding compliancy
//
//  Created by Daniel Barela on 2/10/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension SFPoint : NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true;
    }
}
