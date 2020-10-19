//
//  MockMapViewDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

class MockMapViewDelegate: MapDelegate {
    var mapDidStartLoadingMapClosure: ((MKMapView) -> Void)?
    var mapDidFinishLoadingClosure: ((MKMapView) -> Void)?
    var mapDidFinishRenderingClosure: ((MKMapView, Bool) -> Void)?
    var mapDidAddOverlayViewsClosure: ((MKMapView) -> Void)?
    var regionDidChangeAnimatedClosure: ((MKMapView) -> Void)?

    override func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        mapDidStartLoadingMapClosure?(mapView);
    }
    override func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        //loading done
        mapDidFinishLoadingClosure?(mapView)
    }
    
    override func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // rendering done
        mapDidFinishRenderingClosure?(mapView, fullyRendered);
    }
    
    override func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
        // added overlay views
        mapDidAddOverlayViewsClosure?(mapView);
    }
    
    override func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionDidChangeAnimatedClosure?(mapView)
    }
}
