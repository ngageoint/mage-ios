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
    var imageURL: URL? = nil
    var title: String? = nil
    var coordinate: CLLocationCoordinate2D
    var user: User? = nil
    var feedItem: FeedItem? = nil
    var observation: Observation? = nil
}

protocol StraightLineNavigationDelegate {
    func cancelStraightLineNavigation();
}

class StraightLineNavigation: NSObject {
    var delegate: StraightLineNavigationDelegate?;
    weak var mapView: MKMapView?;
    weak var mapStack: UIStackView?;
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
    
    init(mapView: MKMapView, locationManager: CLLocationManager?, mapStack: UIStackView) {
        self.mapView = mapView;
        self.mapStack = mapStack;
    }
    
    deinit {
        navView?.removeFromSuperview();
        navView = nil
    }
    
    func startNavigation(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D, delegate: StraightLineNavigationDelegate?, image: UIImage?, imageURL: URL?, scheme: MDCContainerScheming? = nil) {
        navigationModeEnabled = true;
        headingModeEnabled = true;
        
        navView = StraightLineNavigationView(locationManager: manager, destinationMarker: image, destinationCoordinate: destinationCoordinate, delegate: delegate, scheme: scheme, targetColor: relativeBearingColor, bearingColor: headingColor);
        navView?.destinationMarkerUrl = imageURL
        updateNavigationLines(manager: manager, destinationCoordinate: destinationCoordinate);
        self.delegate = delegate;
        mapStack?.addArrangedSubview(navView!);
    }
    
    func startHeading(manager: CLLocationManager) {
        headingModeEnabled = true;
        updateHeadingLine(manager: manager);
    }
    
    @discardableResult
    func stopHeading() -> Bool {
        if (!navigationModeEnabled && headingModeEnabled) {
            headingModeEnabled = false;
            if let headingPolyline = headingPolyline {
                mapView?.removeOverlay(headingPolyline);
            }
            return true;
        }
        return false;
    }
    
    func stopNavigation() {
        if let navView = navView {
            navView.removeFromSuperview()
        }
        navigationModeEnabled = false;
        if let relativeBearingPolyline = relativeBearingPolyline {
            mapView?.removeOverlay(relativeBearingPolyline);
        }
        if let headingPolyline = headingPolyline {
            mapView?.removeOverlay(headingPolyline);
        }
    }
    
    func calculateBearingPoint(startCoordinate: CLLocationCoordinate2D, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        var metersDistanceForBearing = 500000.0;
        
        let span = mapView?.region.span ?? MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        let center = mapView?.region.center ?? startCoordinate
        
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
    
    func updateHeadingLine(manager: CLLocationManager) {
        if (self.headingModeEnabled) {
            guard let location = manager.location else {
                return;
            }
            
            guard let userCoordinate = manager.location?.coordinate else {
                return;
            }
            
            // if the user is moving, use their direction of movement
            var bearing = location.course;
            let speed = location.speed;
            
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
                mapView?.removeOverlay(headingPolyline!);
            }
            headingPolyline = NavigationOverlay(points: coordinates, count: 2, color: headingColor)
            headingPolyline?.accessibilityLabel = "heading"
            mapView?.addOverlay(headingPolyline!, level: .aboveLabels);
            navView?.populate(relativeBearingColor: relativeBearingColor, headingColor: headingColor);
        }
    }
    
    func updateNavigationLines(manager: CLLocationManager, destinationCoordinate: CLLocationCoordinate2D?) {
        guard let userCoordinate = manager.location?.coordinate else {
            return;
        }
        if navigationModeEnabled, let destinationCoordinate = destinationCoordinate {
            let userLocationPoint = MKMapPoint(userCoordinate)
            let endCoordinate = MKMapPoint(destinationCoordinate)
            
            let coordinates: [MKMapPoint] = [userLocationPoint, endCoordinate]
            if (relativeBearingPolyline != nil) {
                mapView?.removeOverlay(relativeBearingPolyline!);
            }
            relativeBearingPolyline = NavigationOverlay(points: coordinates, count: 2, color: relativeBearingColor)
            relativeBearingPolyline?.accessibilityLabel = "relative bearing"
            mapView?.addOverlay(relativeBearingPolyline!);
            navView?.populate(relativeBearingColor: relativeBearingColor, headingColor: headingColor, destinationCoordinate: destinationCoordinate);
        }
        
        updateHeadingLine(manager: manager);
    }
}
