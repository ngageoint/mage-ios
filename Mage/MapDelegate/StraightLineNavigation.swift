//
//  StraightLineNavigation.swift
//  MAGE
//
//  Created by Daniel Barela on 3/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class StraightLineNavigation: NSObject {
    
    var bearingLine: NavigationOverlay!
    var navigationLine: NavigationOverlay!
    let mapView: MKMapView!;
    var navigationModeEnabled: Bool = false
    var bearingModeEnabled: Bool = false
    
    @objc public init(mapView: MKMapView, locationManager: CLLocationManager?) {
        self.mapView = mapView;
        self.bearingLine = NavigationOverlay(start: MKMapPoint(x: 0.0, y: 0.0), end: MKMapPoint(x: 0.0, y: 0.0), boundingMapRect: self.mapView.visibleMapRect, color: UIColor.systemRed, lineWidth: 8.0)
        self.navigationLine = NavigationOverlay(start: MKMapPoint(x: 0.0, y: 0.0), end: MKMapPoint(x: 0.0, y: 0.0), boundingMapRect: self.mapView.visibleMapRect, color: UIColor.systemGreen, lineWidth: 16.0)
    }
    
    @objc func startNavigation(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D) {
        self.navigationModeEnabled = true;
        self.bearingModeEnabled = true;
        self.updateNavigationLines(manager: manager, destinationCoordinate: destinationCoordinate);
        self.mapView.addOverlay(self.navigationLine);
        self.mapView.addOverlay(self.bearingLine);
    }
    
    @objc func startBearing(manager: CLLocationManager) {
        self.bearingModeEnabled = true;
        self.updateBearingLine(manager: manager);
        self.mapView.addOverlay(self.bearingLine);
    }
    
    func stopNavigation() {
        self.navigationModeEnabled = false;
        self.mapView.removeOverlay(self.navigationLine);
        self.mapView.removeOverlay(self.bearingLine);
    }
    
    func calculateBearingPoint(startCoordinate: CLLocationCoordinate2D, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        var metersDistanceForBearing = 5000.0;
        
        let span = self.mapView.region.span
        let center = self.mapView.region.center
        
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
            
            guard let bearing = manager.heading?.magneticHeading else {
                return;
            }
            let bearingPoint = MKMapPoint(calculateBearingPoint(startCoordinate: userCoordinate, bearing: bearing));
            
            let userLocationPoint = MKMapPoint(userCoordinate)
            self.bearingLine.startPoint = userLocationPoint
            self.bearingLine.endPoint = bearingPoint;
            self.bearingLine.renderer.setNeedsDisplay();
            print("updating bearing line");
        }
    }
    
    @objc func updateNavigationLines(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D) {
        print("update navigation lines")
        guard let userCoordinate = manager.location?.coordinate else {
            return;
        }
        if (self.navigationModeEnabled) {
            let userLocationPoint = MKMapPoint(userCoordinate)
            let endCoordinate = MKMapPoint(destinationCoordinate)
            
            self.navigationLine.startPoint = userLocationPoint
            self.navigationLine.endPoint = endCoordinate
            self.navigationLine.renderer.setNeedsDisplay();
        }
        
        updateBearingLine(manager: manager);
    }
}
