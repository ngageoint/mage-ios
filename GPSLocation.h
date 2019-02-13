//
//  GPSLocation.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "SFGeometry.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPSLocation : NSManagedObject

- (SFGeometry *) getGeometry;
- (void) setGeometry: (SFGeometry *) geometry;

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
+ (NSArray *) fetchGPSLocationsInManagedObjectContext:(NSManagedObjectContext *) context;
+ (NSArray *) fetchLastXGPSLocations: (NSUInteger) x;
+ (NSURLSessionDataTask *) operationToPushGPSLocations: (NSArray *) locations success: (void (^)(void)) success failure: (void (^)(NSError *)) failure;

@end

NS_ASSUME_NONNULL_END

#import "GPSLocation+CoreDataProperties.h"
