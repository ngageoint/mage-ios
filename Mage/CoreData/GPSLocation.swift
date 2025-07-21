//
//  GPSLocation.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import CoreTelephony
import AFNetworking
import SimpleFeatures

@objc public class GPSLocation: NSManagedObject {
    
    var cllocation: CLLocation? {
        get {
            let centroid: SFPoint = SFGeometryUtils.centroid(of: geometry)
            if let dictionary = properties as? [String : Any] {
                let cllocation = CLLocation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: centroid.y as? CLLocationDegrees ?? 0.0,
                        longitude: centroid.x as? CLLocationDegrees ?? 0.0),
                    altitude: dictionary["altitude"] as? CLLocationDistance ?? 0.0,
                    horizontalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                    verticalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                    timestamp: timestamp ?? Date())
                return cllocation
            } else {
                return CLLocation(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue)
            }
        }
    }
    
    @objc public var geometry: SFGeometry? {
        get {
            if let geometryData = self.geometryData {
                return SFGeometryUtils.decodeGeometry(geometryData);
            }
            return nil;
        }
        set {
            if let newValue = newValue {
                self.geometryData = SFGeometryUtils.encode(newValue);
            }
        }
    }
    
    @objc public static func gpsLocation(location: CLLocation, context: NSManagedObjectContext) -> GPSLocation {
        let gpsLocation = GPSLocation(context: context)
        
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true;
        var batteryState = "";
        switch (device.batteryState) {
        case .full:
            batteryState = "Full";
        case .unknown:
            batteryState = "Unknown";
        case .charging:
            batteryState = "Charging";
        case .unplugged:
            batteryState = "Unplugged";
        @unknown default:
            batteryState = "Unkonwn";
        };
        
        let telephonyInfo = CTTelephonyNetworkInfo();
        let manager = AFNetworkReachabilityManager.shared();
        manager.startMonitoring();
        
        let info = Bundle.main.infoDictionary;
        let appVersion = info?["CFBundleShortVersionString"]
        let buildNumber = info?["CFBundleVersion"]
        
        let point = SFPoint(xValue: location.coordinate.longitude, andYValue: location.coordinate.latitude);
        
        gpsLocation.geometry = point;
        gpsLocation.timestamp = location.timestamp;
        gpsLocation.eventId = Server.currentEventId();
        
        gpsLocation.properties = [
            GPSLocationKey.altitude.key: location.altitude,
            GPSLocationKey.accuracy.key: location.horizontalAccuracy,
            GPSLocationKey.verticalAccuracy.key: location.verticalAccuracy,
            GPSLocationKey.bearing.key: location.course,
            GPSLocationKey.speed.key: location.speed,
            GPSLocationKey.millis.key: location.timestamp.timeIntervalSince1970,
            GPSLocationKey.timestamp.key: Date.ISO8601FormatStyle.gmtZeroString(from: location.timestamp),
            GPSLocationKey.battery_level.key: device.batteryLevel * 100,
            GPSLocationKey.battery_state.key: batteryState,
            GPSLocationKey.telephone_network.key: telephonyInfo.serviceCurrentRadioAccessTechnology ?? "Unknown",
            GPSLocationKey.network.key: manager.localizedNetworkReachabilityStatusString(),
            GPSLocationKey.mage_version.key: "\(appVersion ?? "")-\(buildNumber ?? "")",
            GPSLocationKey.provider.key: "gps",
            GPSLocationKey.system_version.key: device.systemVersion,
            GPSLocationKey.system_name.key: device.systemName,
            GPSLocationKey.device_name.key: device.name,
            GPSLocationKey.device_model.key: device.model
        ];
        return gpsLocation;
    }
    
    @objc public static func fetchGPSLocations(limit: NSNumber?, context: NSManagedObjectContext) -> [GPSLocation] {
        let fetchRequest = GPSLocation.mr_requestAllSorted(by: GPSLocationKey.timestamp.key, ascending: true);
        if let limit = limit {
            fetchRequest.fetchLimit = limit.intValue;
        }
        return (GPSLocation.mr_execute(fetchRequest, in: context) as? [GPSLocation]) ?? [];
    }
    
    @objc public static func operationToPush(locations: [GPSLocation], success: ((URLSessionDataTask?, Any?) -> Void)?, failure: ((Error) -> Void)?) -> URLSessionDataTask? {
        guard let currentEventId = Server.currentEventId(), let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(currentEventId)/locations";
        let manager = MageSessionManager.shared();
        var parameters: [Any] = [];
        for location in locations {
            let point = location.geometry;
            if let centroid = SFGeometryUtils.centroid(of: point) {
                parameters.append([
                    "geometry": [
                        "type": "Point",
                        "coordinates": [centroid.x, centroid.y]
                    ],
                    "properties": location.properties
                ])
            }
        }
        let task = manager?.post_TASK(url,
                                      parameters: parameters, progress: nil,
                                      success: success,
                                      failure: { task, error in
                                        failure?(error);
                                      });
        return task;
    }
}
