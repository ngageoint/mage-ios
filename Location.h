//
//  Location.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "Geometry.h"

@class User;

NS_ASSUME_NONNULL_BEGIN

@interface Location : NSManagedObject

@property (nonatomic, retain) Geometry* geometry;

-(CLLocation *) location;
- (NSString *) sectionName;
- (void) populateLocationFromJson:(NSArray *) locations;
+ (NSOperation *) operationToPullLocationsWithSuccess: (void (^)()) success failure: (void (^)(NSError *)) failure;

@end

NS_ASSUME_NONNULL_END

#import "Location+CoreDataProperties.h"
