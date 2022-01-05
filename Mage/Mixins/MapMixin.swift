//
//  MapMixin.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol MapMixin {
    var mapView: MKMapView? { get set }
    func setupMixin()
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer?
    func traitCollectionUpdated(previous: UITraitCollection?)
    func regionDidChange(mapView: MKMapView)
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView?
    func items(at location: CLLocationCoordinate2D) -> [Any]?
    func applyTheme(scheme: MDCContainerScheming?)
}

extension MapMixin {
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        return nil
    }
    
    func traitCollectionUpdated(previous: UITraitCollection?){ }
    func regionDidChange(mapView: MKMapView) { }
    
    func viewForAnnotation(annotation: MKAnnotation, mapView: MKMapView) -> MKAnnotationView? {
        return nil
    }
    
    func items(at location: CLLocationCoordinate2D) -> [Any]? {
        return nil
    }
    
    func applyTheme(scheme: MDCContainerScheming?) {
    }
}
