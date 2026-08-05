//
//  ObservationSelectionDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 8/5/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


import Foundation
import MapKit
import Persistence

public protocol ObservationSelectionDelegate: AnyObject {
    func selectedObservation(_ observation: Observation)

    func selectedObservation(
        _ observation: Observation,
        region: MKCoordinateRegion
    )

    func observationDetailSelected(_ observation: Observation)

    func getDirections(_ observation: Observation)

    func favorite(_ observation: Observation)
}

public extension ObservationSelectionDelegate {
    func getDirections(_ observation: Observation) { }

    func favorite(_ observation: Observation) { }
}
