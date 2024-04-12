//
//  Locatable.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol Locatable {
    var coordinate: CLLocationCoordinate2D { get }
    var coordinateRegion: MKCoordinateRegion? { get }
    static func getBoundingPredicate(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) -> NSPredicate
}

extension Locatable {
    var coordinateRegion: MKCoordinateRegion? {
        return nil
    }

    static func getBoundingPredicate(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) -> NSPredicate {
        return NSPredicate(
            format: "latitude >= %lf AND latitude <= %lf AND longitude >= %lf AND longitude <= %lf",
            minLat,
            maxLat,
            minLon,
            maxLon
        )
    }
}
