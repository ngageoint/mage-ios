//
//  MapDelegateCLLocationManagerDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 3/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension MapDelegate : CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthorizationChangedDelegate?.locationManager(manager, didChange: status);
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.mapView.showsUserLocation = true;
        straightLineNavigation.updateNavigationLines(manager: manager, destinationCoordinate: navigationDestinationCoordinate);
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        print("New heading is %@", newHeading);
        straightLineNavigation.updateNavigationLines(manager: manager, destinationCoordinate: navigationDestinationCoordinate)
    }
}
