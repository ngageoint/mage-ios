//
//  LocationService.h
//  mage-ios-sdk
//
//  Created by William Newman on 8/18/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const kReportLocationKey;
extern NSString * const kGPSSensitivityKey;
extern NSString * const kLocationReportingFrequencyKey;

@interface LocationService : NSObject<CLLocationManagerDelegate>

+ (instancetype) singleton;

- (void) start;
- (void) stop;

- (CLLocation *) location;

@end
