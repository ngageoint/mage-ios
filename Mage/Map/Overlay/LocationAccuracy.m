//
//  LocationAccuracy.m
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationAccuracy.h"

@implementation LocationAccuracy

+(instancetype) locationAccuracyWithCenterCoordinate:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius timestamp: (NSDate *) timestamp {
    LocationAccuracy *locationAccuracy = [LocationAccuracy circleWithCenterCoordinate:coord radius:radius];
    if (locationAccuracy != nil) {
        locationAccuracy.timestamp = timestamp;
    }
    
    return locationAccuracy;
}

@end
