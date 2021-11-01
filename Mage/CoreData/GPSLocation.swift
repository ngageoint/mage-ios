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
            SFGeometryUtils.decodeGeometry(self.geometryData);
        }
        set {
            self.geometryData = SFGeometryUtils.encode(newValue);
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
                "carrier_name": carrier?.carrierName ?? "No carrier",
                "country_code": carrier?.isoCountryCode ?? "Airplane mode, no sim or out of range",
                "mobile_country_code": carrier?.mobileCountryCode ?? "No sim or out of range"
                ]);
        }
        
        gpsLocation.properties = [
            "altitude": location.altitude,
            "accuracy": location.horizontalAccuracy,
            "verticalAccuracy": location.verticalAccuracy,
            "bearing": location.course,
            "speed": location.speed,
            "millis": location.timestamp.timeIntervalSince1970,
            "timestamp": ISO8601DateFormatter.string(from: location.timestamp, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone]),
            "battery_level": device.batteryLevel * 100,
            "battery_state": batteryState,
            "telephone_network": telephonyInfo.serviceCurrentRadioAccessTechnology ?? "Unknown",
            "carrier_information": carrierInformations,
            "network": manager.localizedNetworkReachabilityStatusString(),
            "mage_version": "\(appVersion ?? "")-\(buildNumber ?? "")",
            "provider": "gps",
            "system_version": device.systemVersion,
            "system_name": device.systemName,
            "device_name": device.name,
            "device_model": device.model
        ];
        return gpsLocation;
    }
    
    @objc public static func fetchGPSLocations(limit: NSNumber?, context: NSManagedObjectContext) -> [GPSLocation] {
        let fetchRequest = GPSLocation.mr_requestAllSorted(by: "timestamp", ascending: true);
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
