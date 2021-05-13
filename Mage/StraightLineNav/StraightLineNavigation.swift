//
//  StraightLineNavigation.swift
//  MAGE
//
//  Created by Daniel Barela on 3/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol StraightLineNavigationDelegate {
    @objc func cancelStraightLineNavigation();
}

@objc class StraightLineNavigation: NSObject {
    var delegate: StraightLineNavigationDelegate?;
    var bearingLine: NavigationOverlay!
    var navigationLine: NavigationOverlay!
    let mapView: MKMapView!;
    let mapStack: UIStackView!;
    var navigationModeEnabled: Bool = false
    var bearingModeEnabled: Bool = false
    var navView: StraightLineNavigationView?;
    //TODO: pull these from preferences
    var targetColor: UIColor = .systemGreen;
    var bearingColor: UIColor = .systemRed;
    
    @objc public init(mapView: MKMapView, locationManager: CLLocationManager?, mapStack: UIStackView) {
        self.mapView = mapView;
        self.mapStack = mapStack;
        self.bearingLine = NavigationOverlay(start: MKMapPoint(x: 0.0, y: 0.0), end: MKMapPoint(x: 0.0, y: 0.0), boundingMapRect: self.mapView.visibleMapRect, color: bearingColor, lineWidth: 8.0)
        self.navigationLine = NavigationOverlay(start: MKMapPoint(x: 0.0, y: 0.0), end: MKMapPoint(x: 0.0, y: 0.0), boundingMapRect: self.mapView.visibleMapRect, color: targetColor, lineWidth: 16.0)
    }
    
    @objc func startNavigation(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D, delegate: StraightLineNavigationDelegate?, image: UIImage?, scheme: MDCContainerScheming? = nil) {
        navigationModeEnabled = true;
        bearingModeEnabled = true;
        updateNavigationLines(manager: manager, destinationCoordinate: destinationCoordinate);
        mapView.addOverlay(navigationLine);
        mapView.addOverlay(bearingLine);
        navView = StraightLineNavigationView(locationManager: manager, destinationMarker: image, destinationCoordinate: destinationCoordinate, delegate: delegate, scheme: scheme, targetColor: targetColor, bearingColor: bearingColor);
        self.delegate = delegate;
        mapStack.addArrangedSubview(navView!);
    }
    
    @objc func startBearing(manager: CLLocationManager) {
        bearingModeEnabled = true;
        updateBearingLine(manager: manager);
        mapView.addOverlay(bearingLine);
    }
    
    @objc func stopNavigation() {
        navigationModeEnabled = false;
        mapView.removeOverlay(navigationLine);
        mapView.removeOverlay(bearingLine);
        navView?.removeFromSuperview();
    }
    
    func calculateBearingPoint(startCoordinate: CLLocationCoordinate2D, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        var metersDistanceForBearing = 5000.0;
        
        let span = mapView.region.span
        let center = mapView.region.center
        
        let loc1 = CLLocation(latitude: center.latitude - span.latitudeDelta, longitude: center.longitude)
        let loc2 = CLLocation(latitude: center.latitude + span.latitudeDelta, longitude: center.longitude)
        let loc3 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta)
        let loc4 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta)
        
        metersDistanceForBearing = max(loc1.distance(from: loc2), loc3.distance(from: loc4)) * 2.0
        
        let radDirection = bearing * (.pi / 180.0);

        return locationWithBearing(bearing: radDirection, distanceMeters: metersDistanceForBearing, origin: startCoordinate)
    }
    
    func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6) // earth radius in meters
        
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
    
    @objc func updateBearingLine(manager: CLLocationManager) {
        if (self.bearingModeEnabled) {
            guard let userCoordinate = manager.location?.coordinate else {
                return;
            }
            
            guard let bearing = manager.heading?.trueHeading else {
                return;
            }
            let bearingPoint = MKMapPoint(calculateBearingPoint(startCoordinate: userCoordinate, bearing: bearing));
            
            let userLocationPoint = MKMapPoint(userCoordinate)
            bearingLine.startPoint = userLocationPoint
            bearingLine.endPoint = bearingPoint;
            bearingLine.renderer.setNeedsDisplay();
            navView?.populate();
            print("updating bearing line");
        }
    }
    
    @objc func updateNavigationLines(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D) {
        print("update navigation lines")
        guard let userCoordinate = manager.location?.coordinate else {
            return;
        }
        if (navigationModeEnabled) {
            let userLocationPoint = MKMapPoint(userCoordinate)
            let endCoordinate = MKMapPoint(destinationCoordinate)
            
            navigationLine.startPoint = userLocationPoint
            navigationLine.endPoint = endCoordinate
            navigationLine.renderer.setNeedsDisplay();
            navView?.populate();
        }
        
        updateBearingLine(manager: manager);
    }
}
