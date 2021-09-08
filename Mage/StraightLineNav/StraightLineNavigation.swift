//
//  StraightLineNavigation.swift
//  MAGE
//
//  Created by Daniel Barela on 3/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct StraightLineNavigationNotification {
    var image: UIImage? = nil
    var coordinate: CLLocationCoordinate2D
    var user: User? = nil
    var feedItem: FeedItem? = nil
}

@objc protocol StraightLineNavigationDelegate {
    @objc func cancelStraightLineNavigation();
}

@objc class StraightLineNavigation: NSObject {
    var delegate: StraightLineNavigationDelegate?;
    let mapView: MKMapView!;
    let mapStack: UIStackView!;
    var navigationModeEnabled: Bool = false
    var headingModeEnabled: Bool = false
    var navView: StraightLineNavigationView?;
    
    var headingPolyline: NavigationOverlay?;
    var relativeBearingPolyline: NavigationOverlay?;
    
    var relativeBearingColor: UIColor {
        get {
            return UserDefaults.standard.bearingTargetColor;
        }
    }
    var headingColor: UIColor {
        get {
            return UserDefaults.standard.headingColor;
        }
    }
    
    @objc public init(mapView: MKMapView, locationManager: CLLocationManager?, mapStack: UIStackView) {
        self.mapView = mapView;
        self.mapStack = mapStack;
    }
    
    @objc func startNavigation(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D, delegate: StraightLineNavigationDelegate?, image: UIImage?, scheme: MDCContainerScheming? = nil) {
        navigationModeEnabled = true;
        headingModeEnabled = true;
        
        updateNavigationLines(manager: manager, destinationCoordinate: destinationCoordinate);
        navView = StraightLineNavigationView(locationManager: manager, destinationMarker: image, destinationCoordinate: destinationCoordinate, delegate: delegate, scheme: scheme, targetColor: relativeBearingColor, bearingColor: headingColor);
        self.delegate = delegate;
        mapStack.addArrangedSubview(navView!);
    }
    
    @objc func startHeading(manager: CLLocationManager) {
        headingModeEnabled = true;
        updateHeadingLine(manager: manager);
    }
    
    @objc func stopHeading() -> Bool {
        if (!navigationModeEnabled && headingModeEnabled) {
            headingModeEnabled = false;
            if let safeHeadingPolyline = headingPolyline {
                mapView.removeOverlay(safeHeadingPolyline);
            }
            return true;
        }
        return false;
    }
    
    @objc func stopNavigation() {
        navigationModeEnabled = false;
        if let safeRelativeBearingPolyline = relativeBearingPolyline {
            mapView.removeOverlay(safeRelativeBearingPolyline);
        }
        if let safeHeadingPolyline = headingPolyline {
            mapView.removeOverlay(safeHeadingPolyline);
        }
        navView?.removeFromSuperview();
    }
    
    func calculateBearingPoint(startCoordinate: CLLocationCoordinate2D, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        var metersDistanceForBearing = 500000.0;
        
        let span = mapView.region.span
        let center = mapView.region.center
        
        let loc1 = CLLocation(latitude: center.latitude - span.latitudeDelta, longitude: center.longitude)
        let loc2 = CLLocation(latitude: center.latitude + span.latitudeDelta, longitude: center.longitude)
        let loc3 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta)
        let loc4 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta)
        
        metersDistanceForBearing = min(metersDistanceForBearing, max(loc1.distance(from: loc2), loc3.distance(from: loc4)) * 2.0)
        
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
    
    @objc func updateHeadingLine(manager: CLLocationManager) {
        if (self.headingModeEnabled) {
            guard let location = manager.location else {
                return;
            }
            
            guard let userCoordinate = manager.location?.coordinate else {
                return;
            }
            
            var bearing = location.course;
            let speed = location.speed;
            // if the user is moving, use their direction of movement
            if (bearing < 0 || speed <= 0) {
                // if the user is not moving, use the heading of the phone
                if let trueHeading = manager.heading?.trueHeading {
                    bearing = trueHeading;
                } else {
                    return;
                }
            }
            let bearingPoint = MKMapPoint(calculateBearingPoint(startCoordinate: userCoordinate, bearing: bearing));
            
            let userLocationPoint = MKMapPoint(userCoordinate)
            let coordinates: [MKMapPoint] = [userLocationPoint, bearingPoint]
            if (headingPolyline != nil) {
                mapView.removeOverlay(headingPolyline!);
            }
            headingPolyline = NavigationOverlay(points: coordinates, count: 2, color: headingColor)
            mapView.addOverlay(headingPolyline!, level: .aboveLabels);
            navView?.populate(relativeBearingColor: relativeBearingColor, headingColor: headingColor);
        }
    }
    
    @objc func updateNavigationLines(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D) {
        guard let userCoordinate = manager.location?.coordinate else {
            return;
        }
        if (navigationModeEnabled) {
            let userLocationPoint = MKMapPoint(userCoordinate)
            let endCoordinate = MKMapPoint(destinationCoordinate)
            
            let coordinates: [MKMapPoint] = [userLocationPoint, endCoordinate]
            if (relativeBearingPolyline != nil) {
                mapView.removeOverlay(relativeBearingPolyline!);
            }
            relativeBearingPolyline = NavigationOverlay(points: coordinates, count: 2, color: relativeBearingColor)
            mapView.addOverlay(relativeBearingPolyline!);
        }
        
        updateHeadingLine(manager: manager);
    }
}
