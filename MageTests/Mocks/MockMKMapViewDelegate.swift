//
//  MockMKMapViewDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 3/16/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MockMKMapViewDelegate: NSObject, MKMapViewDelegate {
    var finishedRendering = false;
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        finishedRendering = true;
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
    }
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        
    }
    
    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
        
    }
    
    func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
        
    }
}
