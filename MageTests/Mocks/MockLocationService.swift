//
//  MockLocationService.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockLocationService: LocationService {
    
    var mockedLocation: CLLocation?;
    
    override init() {
        mockedLocation = CLLocation(latitude: 40.0085, longitude: -105.2678);
        super.init();
        UserDefaults.standard.removeObserver(self, forKeyPath: "reportLocation");
        UserDefaults.standard.removeObserver(self, forKeyPath: "gpsDistanceFilter");
        UserDefaults.standard.removeObserver(self, forKeyPath: "userReportingFrequency");
    }
    
    override func location() -> CLLocation! {
        return mockedLocation;
    }

}
