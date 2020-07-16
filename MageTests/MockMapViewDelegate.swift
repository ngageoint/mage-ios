//
//  MockMapViewDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

class MockMapViewDelegate: NSObject, MKMapViewDelegate {
    var mapDidStartLoadingMapClosure: ((MKMapView) -> Void)?
    var mapDidFinishLoadingClosure: ((MKMapView) -> Void)?
    var mapDidFinishRenderingClosure: ((MKMapView, Bool) -> Void)?
    var mapDidAddOverlayViewsClosure: ((MKMapView) -> Void)?
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        mapDidStartLoadingMapClosure?(mapView);
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        //loading done
        mapDidFinishLoadingClosure?(mapView)
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // rendering done
        mapDidFinishRenderingClosure?(mapView, fullyRendered);
    }
    
    func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
        // added overlay views
        mapDidAddOverlayViewsClosure?(mapView);
    }
}
