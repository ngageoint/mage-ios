//
//  DataConnectionUtilities.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 2/7/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork

@objc public enum ConnectionType : Int {
    case unknown
    case none
    case cell
    case wiFi
}

@objc public enum WIFIRestrictionType : Int {
    case NoRestrictions
    case OnlyTheseWifiNetworks
    case NotTheseWifiNetworks
}

@objc public enum NetworkAllowType : Int {
    case all
    case wiFiOnly
    case none
}

@objc class DataConnectionUtilities : NSObject {
    
    
    @objc public static func connectionType() -> ConnectionType {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .none
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .none
        }
        
        let isReachable = flags.contains(.reachable)
        
        if (!isReachable) {
            return .none
        } else if (flags.contains(.isWWAN)) {
            return .cell
        } else {
            return .wiFi
        }
    }
    
    @objc public static func getCurrentWifiSsid() -> String? {
        if DataConnectionUtilities.connectionType() != .wiFi {
            return nil
        }
        
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        let ssids: [String] = interfaceNames.compactMap { name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            return ssid
        }
        
        if !ssids.isEmpty {
            return ssids[0]
        }
        return nil
    }
    
    static func currentWiFiAllowed() -> Bool {
        let wifiNetworkRestrictionType = UserDefaults.standard.wifiNetworkRestrictionType
        
        if wifiNetworkRestrictionType == .NoRestrictions {
            return true
        }
        
        let currentSSID = DataConnectionUtilities.getCurrentWifiSsid()
        if (wifiNetworkRestrictionType == .OnlyTheseWifiNetworks) {
            if let currentSSID = currentSSID, UserDefaults.standard.wifiWhitelist.contains(currentSSID) {
                return true
            }
        } else if (wifiNetworkRestrictionType == .NotTheseWifiNetworks) {
            if let currentSSID = currentSSID {
                return !UserDefaults.standard.wifiBlacklist.contains(currentSSID)
            } else {
                return true
            }
        }
        return false
    }
    
    static func shouldPerformNetworkOperation(_ preferencesKey: String) -> Bool {
        let networkOption = UserDefaults.standard.integer(forKey: preferencesKey)
        guard let networkAllowType = NetworkAllowType(rawValue: networkOption) else {
            return false
        }
        
        if networkAllowType == .all {
            return true
        } else if networkAllowType == .wiFiOnly {
            if DataConnectionUtilities.connectionType() == .wiFi {
                return DataConnectionUtilities.currentWiFiAllowed()
            } else {
                return false
            }
        } else if networkAllowType == .none {
            return false
        }
        return false
    }
    
    @objc public static func shouldPushObservations() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("observationPushNetworkOption");
    }
    
    @objc public static func shouldFetchObservations() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("observationFetchNetworkOption");
    }
    
    @objc public static func shouldPushLocations() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("locationPushNetworkOption");
    }
    
    @objc public static func shouldFetchLocations() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("locationFetchNetworkOption");
    }
    
    @objc public static func shouldPushAttachments() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("attachmentPushNetworkOption");
    }
    
    @objc public static func shouldFetchAttachments() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("attachmentFetchNetworkOption");
    }
    
    @objc public static func shouldFetchAvatars() -> Bool {
        return DataConnectionUtilities.shouldPerformNetworkOperation("attachmentFetchNetworkOption");
    }
  
}
