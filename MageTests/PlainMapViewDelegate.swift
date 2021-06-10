//
//  PlainMapViewDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

class PlainMapViewDelegate: NSObject, MKMapViewDelegate {
    public var mockMapViewDelegate: MockMapViewDelegate?;

    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        mockMapViewDelegate?.mapDidStartLoadingMapClosure?(mapView);
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        //loading done
        mockMapViewDelegate?.mapDidFinishLoadingClosure?(mapView)
    }

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // rendering done
        mockMapViewDelegate?.mapDidFinishRenderingClosure?(mapView, fullyRendered);
    }

    func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
        // added overlay views
        mockMapViewDelegate?.mapDidAddOverlayViewsClosure?(mapView);
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mockMapViewDelegate?.regionDidChangeAnimatedClosure?(mapView)
    }

}
