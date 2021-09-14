//
//  MagePropertiesTransformer.swift
//  MAGE
//
//  Created by Daniel Barela on 9/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

@objc(MagePropertiesTransformer)
class MagePropertiesTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return super.allowedTopLevelClasses + [SFGeometry.self]
    }
}
