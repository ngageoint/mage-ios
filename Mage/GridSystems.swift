//
//  GridSystems.swift
//  MAGE
//
//  Created by Brian Osborn on 9/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import GARS
import MGRS

/**
 * Grid Systems support for GARS and MGRS grid tile overlays and coordinates
 */
@objc public class GridSystems : NSObject {

    @objc public static func garsTileOverlay() -> GARSTileOverlay {
        let tileOverlay = GARSTileOverlay()
        // Customize GARS grid as needed here
        return tileOverlay
    }

    @objc public static func mgrsTileOverlay() -> MGRSTileOverlay {
        let tileOverlay = MGRSTileOverlay()
        // Customize MGRS grid as needed here
        return tileOverlay
    }

    @objc public static func gars(_ coordinate: CLLocationCoordinate2D) -> String {
        return GARS.coordinate(coordinate)
    }

    @objc public static func mgrs(_ coordinate: CLLocationCoordinate2D) -> String {
        return MGRS.coordinate(coordinate)
    }
    
    @objc public static func garsParse(_ coordinate: String) -> CLLocationCoordinate2D {
        return GARS.parseToCoordinate(coordinate)
    }
    
    @objc public static func mgrsParse(_ coordinate: String) -> CLLocationCoordinate2D {
        return MGRS.parseToCoordinate(coordinate)
    }
    
}
