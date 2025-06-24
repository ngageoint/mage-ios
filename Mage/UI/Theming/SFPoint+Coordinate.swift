//
//  SFPoint+Coordinate.swift
//  MAGE
//
//  Created by Brent Michalski on June 18, 2025.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreLocation

extension SFPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: self.y?.doubleValue ?? 0.0,
            longitude: self.x?.doubleValue ?? 0.0
        )
    }
}
