//
//  GPSLocation+helper.h
//  mage-ios-sdk
//
//  Created by William Newman on 8/20/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "GPSLocation.h"
#import <CoreLocation/CoreLocation.h>

@interface GPSLocation (helper)

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location;
+ (NSArray *) fetchGPSLocations;

+ (NSOperation *) operationToPushGPSLocations:(NSArray *) locations success:(void (^)()) success failure: (void (^)()) failure;

@end
