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
        NSLog("Map view will start loading map")
        mapDidStartLoadingMapClosure?(mapView);
    }
    override func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        //loading done
        NSLog("Map view did finish loading map")
        mapDidFinishLoadingClosure?(mapView)
    }
    
    override func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // rendering done
        NSLog("Map view did finish rendering map")
        mapDidFinishRenderingClosure?(mapView, fullyRendered);
    }
    
    override func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
        // added overlay views
        NSLog("Map view did add overlay views")
        mapDidAddOverlayViewsClosure?(mapView);
    }
    
    override func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSLog("Map view region did change")
        regionDidChangeAnimatedClosure?(mapView)
    }
}
