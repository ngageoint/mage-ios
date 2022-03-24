//
//  MockGeometryEditCoordinator.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/10/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import sf_ios

class MockGeometryEditCoordinator : GeometryEditCoordinator {
    var _currentGeometry: SFGeometry! = SFPoint(x: 1.0, andY: 1.0);
    var _fieldName: String! = "Field Name"
    var _pinImage: UIImage! = UIImage(named: "observations")
    
    override func start() {
        
    }
    
    override func update(_ geometry: SFGeometry!) {
        _currentGeometry = geometry;
    }
    
    override var currentGeometry: SFGeometry! {
        get {
            return _currentGeometry
        }
        set {
            _currentGeometry = newValue
        }
    }
    
    override var pinImage: UIImage! {
        get {
            return _pinImage
        }
        set {
            _pinImage = newValue
        }
    }
    
    override func fieldName() -> String! {
        return _fieldName
    }
    
}
