//
//  PersistedMapState.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework
import Combine

class PersistedMapStateMixin: NSObject, MapMixin {
    var cancellables = Set<AnyCancellable>()
    
    @Injected(\.mapStateRepository)
    var mapStateRepository: MapStateRepository
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {
        for cancellable in cancellables {
            cancellable.cancel()
            cancellables.remove(cancellable)
        }
    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        mapStateRepository.$region.sink { region in
            if let region = region {
                UserDefaults.standard.mapRegion = region
            }
        }
        .store(in: &cancellables)
        setMapState(mapView: mapView)
    }
    
    func setMapState(mapView: MKMapView) {
        let region = UserDefaults.standard.mapRegion
        if CLLocationCoordinate2DIsValid(region.center) {
            mapView.region = region
        }
    }
}
