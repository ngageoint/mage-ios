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
import sf_ios

@objc public class GPSLocation: NSManagedObject {
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
    
    @objc public static func gpsLocation(location: CLLocation, context: NSManagedObjectContext) -> GPSLocation? {
        guard let gpsLocation = GPSLocation.mr_createEntity(in: context) else {
            return nil;
        }
        
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
        
        let radioTechDict = telephonyInfo.serviceCurrentRadioAccessTechnology ?? [:];
        let carrierInfoDict : [String : CTCarrier] = telephonyInfo.serviceSubscriberCellularProviders ?? [:];

        var carrierInformations: [[AnyHashable:Any]] = [];
        for key in radioTechDict.keys {
            let carrier = carrierInfoDict[key];
            carrierInformations.append([
                GPSLocationKey.carrier_name.key: carrier?.carrierName ?? "No carrier",
                GPSLocationKey.country_code.key: carrier?.isoCountryCode ?? "Airplane mode, no sim or out of range",
                GPSLocationKey.mobile_country_code.key: carrier?.mobileCountryCode ?? "No sim or out of range"
                ]);
        }
        
        gpsLocation.properties = [
            GPSLocationKey.altitude.key: location.altitude,
            GPSLocationKey.accuracy.key: location.horizontalAccuracy,
            GPSLocationKey.verticalAccuracy.key: location.verticalAccuracy,
            GPSLocationKey.bearing.key: location.course,
            GPSLocationKey.speed.key: location.speed,
            GPSLocationKey.millis.key: location.timestamp.timeIntervalSince1970,
            GPSLocationKey.timestamp.key: ISO8601DateFormatter.string(from: location.timestamp, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone]),
            GPSLocationKey.battery_level.key: device.batteryLevel * 100,
            GPSLocationKey.battery_state.key: batteryState,
            GPSLocationKey.telephone_network.key: telephonyInfo.serviceCurrentRadioAccessTechnology ?? "Unknown",
            GPSLocationKey.carrier_information.key: carrierInformations,
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
        let url = "\(MageServer.baseURL().absoluteURL)/api/events/\(Server.currentEventId())/locations";
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
