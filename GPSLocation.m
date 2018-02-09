//
//  GPSLocation.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GPSLocation.h"

#import "MageSessionManager.h"
#import "NSDate+Iso8601.h"
#import "MageServer.h"
#import "Server.h"
#import "WKBPoint.h"
#import "WKBGeometryUtils.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@implementation GPSLocation

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = YES;
    NSString *batteryState = @"";
    switch (device.batteryState) {
        case UIDeviceBatteryStateFull:
            batteryState = @"Full";
            break;
        case UIDeviceBatteryStateUnknown:
            batteryState = @"Unknown";
            break;
        case UIDeviceBatteryStateCharging:
            batteryState = @"Charging";
            break;
        case UIDeviceBatteryStateUnplugged:
            batteryState = @"Unplugged";
            break;
    }
    
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey: @"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    GPSLocation *gpsLocation = [GPSLocation MR_createEntityInContext:managedObjectContext];
    
    gpsLocation.geometry = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
    gpsLocation.timestamp = location.timestamp;
    gpsLocation.eventId = [Server currentEventId];
    gpsLocation.properties = @{
                               @"altitude": [NSNumber numberWithDouble:location.altitude],
                               @"accuracy": [NSNumber numberWithDouble:location.horizontalAccuracy],
                               @"verticalAccuracy": [NSNumber numberWithDouble:location.verticalAccuracy],
                               @"bearing": [NSNumber numberWithDouble:location.course],
                               @"speed": [NSNumber numberWithDouble:location.speed],
                               @"millis":[NSNumber numberWithDouble: location.timestamp.timeIntervalSince1970],
                               @"timestamp": [location.timestamp iso8601String],
                               @"battery_level": [NSNumber numberWithDouble:device.batteryLevel*100],
                               @"battery_state": batteryState,
                               @"telephone_network": telephonyInfo.currentRadioAccessTechnology != nil ? telephonyInfo.currentRadioAccessTechnology : @"Unknown",
                               @"network": manager.localizedNetworkReachabilityStatusString,
                               @"mage_version": [NSString stringWithFormat:@"%@-%@", appVersion, buildNumber],
                               @"provider": @"gps",
                               @"system_version": [device systemVersion],
                               @"system_name": [device systemName],
                               @"device_name": [device name],
                               @"device_model": [device model]
                               };
    
    return gpsLocation;
}

+ (NSArray *) fetchGPSLocationsInManagedObjectContext:(NSManagedObjectContext *) context {
    return [GPSLocation MR_findAllSortedBy:@"timestamp" ascending:YES inContext:context];
}

+ (NSArray *) fetchLastXGPSLocations: (NSUInteger) limit {
    NSFetchRequest *fetchRequest = [GPSLocation MR_requestAllSortedBy:@"timestamp" ascending:YES];
    fetchRequest.fetchLimit = limit;
    
    return [GPSLocation MR_executeFetchRequest:fetchRequest];
}

+ (NSURLSessionDataTask *) operationToPushGPSLocations:(NSArray *) locations success:(void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/locations", [MageServer baseURL], [Server currentEventId]];
    NSLog(@"Pushing locations to server %@", url);
    
    
    MageSessionManager *manager = [MageSessionManager manager];
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    for (GPSLocation *location in locations) {
        WKBGeometry *point = location.geometry;
        WKBPoint *centroid = [WKBGeometryUtils centroidOfGeometry:point];
        [parameters addObject:@{
                                @"geometry": @{
                                        @"type": @"Point",
                                        @"coordinates": @[centroid.x, centroid.y]
                                        },
                                @"properties": [NSDictionary dictionaryWithDictionary:location.properties]
                                }];
    }
    
    NSURLSessionDataTask *task = [manager POST_TASK:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}
@end
