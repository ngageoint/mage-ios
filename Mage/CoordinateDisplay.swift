//
//  CoordinateDisplay.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import mgrs

class CoordinateDisplay: NSObject {
    @objc public static func displayFromCoordinate(coordinate: CLLocationCoordinate2D) -> String {
        if (UserDefaults.standard.showMGRS) {
            return MGRS.mgrSfromCoordinate(coordinate);
        } else {
            return String(format: "%.05f, %.05f", coordinate.latitude, coordinate.longitude);
        }
    }
}
