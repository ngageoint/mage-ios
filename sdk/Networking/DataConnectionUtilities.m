//
//  DataConnectionUtilities.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 2/7/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "DataConnectionUtilities.h"

@implementation DataConnectionUtilities

+ (ConnectionType)connectionType {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    if (!success) {
        return ConnectionTypeUnknown;
    }
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);

    if (!isNetworkReachable) {
        return ConnectionTypeNone;
    } else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        //connection type
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
        NSDictionary *carrier = [netinfo serviceSubscriberCellularProviders];
        NSDictionary *radio = [netinfo serviceCurrentRadioAccessTechnology];

        NSLog(@"Carrier %@", carrier);
        NSLog(@"Radio %@", radio);

        return ConnectionTypeCell;
    } else {
        return ConnectionTypeWiFi;
    }
}

+ (NSString *) getCurrentWifiSsid {
    NSString *wifiName;
    enum ConnectionType type = [DataConnectionUtilities connectionType];
    if (type == ConnectionTypeWiFi) {
        CFArrayRef interfaces = CNCopySupportedInterfaces();
        if (interfaces) {
            CFIndex count = CFArrayGetCount(interfaces);
            for (int i = 0; i < count; i++) {
                CFStringRef interface = (CFStringRef)CFArrayGetValueAtIndex(interfaces, i);
                NSLog(@"Interface %@", interface);
                NSDictionary *dictionary = (__bridge NSDictionary*)CNCopyCurrentNetworkInfo(interface);
                NSLog(@"Dictionary %@", dictionary);
                // if dictionary is nil then there is no wifi
                if (dictionary) {
                    wifiName = [NSString stringWithFormat:@"%@",[dictionary objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID]];
                }
            }
            CFRelease(interfaces);
        }
    }
    return wifiName;
}

+ (BOOL) currentWiFiAllowed {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger wifiNetworkRestrictionType = [[defaults objectForKey:@"wifiNetworkRestrictionType"] longValue];
    if (wifiNetworkRestrictionType == WIFIRestrictionTypeNoRestrictions) {
        return true;
    }
    
    NSString *currentSSID = [DataConnectionUtilities getCurrentWifiSsid];
    if (wifiNetworkRestrictionType == WIFIRestrictionTypeOnlyTheseWifiNetworks) {
        NSArray *whitelist = [defaults objectForKey:@"wifiWhitelist"];
        if (currentSSID && [whitelist containsObject:currentSSID]) {
            return true;
        }
    } else if (wifiNetworkRestrictionType == WIFIRestrictionTypeNotTheseWifiNetworks) {
        NSArray *blacklist = [defaults objectForKey:@"wifiBlacklist"];
        if (!currentSSID || ![blacklist containsObject:currentSSID]) {
            return true;
        }
    }
    
    return false;
}

+ (BOOL) shouldPerformNetworkOperation: (NSString *) preferencesKey {
    // 0 = all 1 = wifionly 2 = none
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger observationPushNetworkOption = [[defaults objectForKey:preferencesKey] longValue];
    if (!observationPushNetworkOption || observationPushNetworkOption == NetworkAllowTypeAll) {
        return true;
    } else if (observationPushNetworkOption == NetworkAllowTypeWiFiOnly) {
        if ([DataConnectionUtilities connectionType] == ConnectionTypeWiFi) {
            return [DataConnectionUtilities currentWiFiAllowed];
        } else {
            return false;
        }
    } else if (observationPushNetworkOption == NetworkAllowTypeNone) {
        return false;
    }
    return false;
}

+ (BOOL) shouldPushObservations {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"observationPushNetworkOption"];
}

+ (BOOL) shouldFetchObservations {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"observationFetchNetworkOption"];
}

+ (BOOL) shouldFetchLocations {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"locationFetchNetworkOption"];
}

+ (BOOL) shouldPushLocations {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"locationPushNetworkOption"];
}

+ (BOOL) shouldPushAttachments {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"attachmentPushNetworkOption"];
}

+ (BOOL) shouldFetchAttachments {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"attachmentFetchNetworkOption"];
}

+ (BOOL) shouldFetchAvatars {
    return [DataConnectionUtilities shouldPerformNetworkOperation:@"attachmentFetchNetworkOption"];
}

@end
