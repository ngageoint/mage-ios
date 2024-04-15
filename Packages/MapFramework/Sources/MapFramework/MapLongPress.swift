//
//  MapLongPress.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapLongPress: UILongPressGestureRecognizer {
    var mapView: MKMapView?
    var coordinator: MapCoordinator

    init(coordinator: MapCoordinator, mapView: MKMapView) {
        self.mapView = mapView
        self.coordinator = coordinator
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
        self.delegate = self
    }

    @objc private func execute() {
        coordinator.longPressGesture(longPressGestureRecognizer: self)
    }
}

extension MapLongPress: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
