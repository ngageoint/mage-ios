//
//  MockCLLocationManager.swift
//  MAGETests
//
//  Created by Daniel Barela on 4/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreLocation

class MockCLHeading : CLHeading {
    
    var mockedMagneticHeading: CLLocationDirection = 212.3134
    var mockedTrueHeading: CLLocationDirection = 231.43123
    
    override var magneticHeading: CLLocationDirection {
        return mockedMagneticHeading;
    }
    
    override var trueHeading: CLLocationDirection {
        return mockedTrueHeading;
    }
    
    override init() {
        super.init();
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MockCLLocationManager : CLLocationManager {
    
    var mockedLocation: CLLocation?
    var mockedHeading: CLHeading?
    var _authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    var _delegate: CLLocationManagerDelegate?
    public var updatingHeading: Bool = false
    public var updatingLocation: Bool = false
    
    override var authorizationStatus: CLAuthorizationStatus {
        get {
            return _authorizationStatus
        }
        set {
            _authorizationStatus = newValue
        }
    }
    
    override var delegate: CLLocationManagerDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
            _delegate?.locationManagerDidChangeAuthorization?(self)
        }
    }
    
    override init() {
        mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, course: 200, courseAccuracy: 12.0, speed: 254.0, speedAccuracy: 15.0, timestamp: Date());
        mockedHeading = MockCLHeading();
        super.init();
    }
    
    func updateMockedLocation(location: CLLocation) {
        mockedLocation = location
        if updatingLocation {
            delegate?.locationManager?(self, didUpdateLocations: [location])
        }
    }
    
    func updateMockedHeading(heading: CLHeading) {
        mockedHeading = heading
        if updatingHeading {
            delegate?.locationManager?(self, didUpdateHeading: heading)
        }
    }

    override var location: CLLocation? {
        return mockedLocation;
    }
    
    override var heading: CLHeading? {
        return mockedHeading;
    }
    
    override func stopUpdatingHeading() {
        updatingHeading = false
    }
    
    override func startUpdatingHeading() {
        updatingHeading = true
    }
    
    override func stopUpdatingLocation() {
        updatingLocation = false
    }
    
    override func startUpdatingLocation() {
        updatingLocation = true
    }
}
