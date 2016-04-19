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

NS_ASSUME_NONNULL_BEGIN

@interface GPSLocation : NSManagedObject

+ (GPSLocation *) gpsLocationForLocation:(CLLocation *) location inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
+ (NSArray *) fetchGPSLocationsInManagedObjectContext:(NSManagedObjectContext *) context;
+ (NSArray *) fetchLastXGPSLocations: (NSUInteger) x;
+ (NSOperation *) operationToPushGPSLocations: (NSArray *) locations success: (void (^)()) success failure: (void (^)(NSError *)) failure;

@end

NS_ASSUME_NONNULL_END

#import "GPSLocation+CoreDataProperties.h"
