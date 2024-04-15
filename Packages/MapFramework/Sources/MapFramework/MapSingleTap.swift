//
//  MapSingleTap.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

class MapSingleTap: UITapGestureRecognizer {
    var mapView: MKMapView?
    var coordinator: MapCoordinator

    init(coordinator: MapCoordinator, mapView: MKMapView) {
        self.mapView = mapView
        self.coordinator = coordinator
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }

    @objc private func execute() {
        coordinator.singleTapGesture(tapGestureRecognizer: self)
    }
}
