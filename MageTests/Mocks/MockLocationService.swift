//
//  MockLocationService.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE
import CoreLocation

class MockLocationService: LocationService {
    
    var mockedLocation: CLLocation?;
    
    override init() {
        mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.0085, longitude: -105.2678), altitude: 5, horizontalAccuracy: 6, verticalAccuracy: 7, course: 90, speed: 58, timestamp: Date())
        super.init();
        UserDefaults.standard.removeObserver(self, forKeyPath: "reportLocation");
        UserDefaults.standard.removeObserver(self, forKeyPath: "gpsDistanceFilter");
        UserDefaults.standard.removeObserver(self, forKeyPath: "userReportingFrequency");
    }
    
    override func location() -> CLLocation! {
        return mockedLocation;
    }

}
