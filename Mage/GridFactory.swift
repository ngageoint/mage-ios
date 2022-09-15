//
//  GridFactory.swift
//  MAGE
//
//  Created by Brian Osborn on 9/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import gars_ios
import mgrs_ios

/**
 * Factory to create GARS and MGRS grid tile overlays
 */
@objc public class GridFactory : NSObject {

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

}
