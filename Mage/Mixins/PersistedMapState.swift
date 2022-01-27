//
//  PersistedMapState.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol PersistedMapState {
    var mapView: MKMapView? { get set }
    var persistedMapStateMixin: PersistedMapStateMixin? { get set }
}

class PersistedMapStateMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var persistedMapState: PersistedMapState?
    
    init(persistedMapState: PersistedMapState) {
        self.persistedMapState = persistedMapState
    }
    
    deinit {
    }
    
    func setupMixin() {
        setMapState()
    }
    
    func setMapState() {
        let region = UserDefaults.standard.mapRegion
        if CLLocationCoordinate2DIsValid(region.center) {
            persistedMapState?.mapView?.region = region
        }
    }
    
    func regionDidChange(mapView: MKMapView, animated: Bool) {
        UserDefaults.standard.mapRegion = mapView.region
    }
}
