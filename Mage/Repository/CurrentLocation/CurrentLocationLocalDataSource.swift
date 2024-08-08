//
//  CurrentLocationLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct CurrentLocationLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: CurrentLocationLocalDataSource = CurrentLocationCLLocationDataSource()
}

extension InjectedValues {
    var currentLocationLocalDataSource: CurrentLocationLocalDataSource {
        get { Self[CurrentLocationLocalDataSourceProviderKey.self] }
        set { Self[CurrentLocationLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol CurrentLocationLocalDataSource {
    func requestAuthorization()
    func observeLastLocation() -> Published<CLLocation?>.Publisher
    func getLastLocation() -> CLLocation?
}

class CurrentLocationCLLocationDataSource: NSObject,
    CurrentLocationLocalDataSource,
    ObservableObject,
    CLLocationManagerDelegate
{
    var locationManager: CLLocationManager?
    
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager?.distanceFilter = UserDefaults.standard.double(forKey: "gpsDistanceFilter")
        self.locationManager?.allowsBackgroundLocationUpdates = true
        self.locationManager?.delegate = self
        self.requestAuthorization()
    }
    
    func getLastLocation() -> CLLocation? {
        return lastLocation
    }
    
    func observeLastLocation() -> Published<CLLocation?>.Publisher {
        return $lastLocation
    }
    
    func requestAuthorization() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            DispatchQueue.main.async {
                self.locationManager?.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
    }
}
