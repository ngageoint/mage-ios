//
//  Location+helper.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Location.h"
#import <CoreLocation/CoreLocation.h>

@interface Location (helper)

+ (Location *) locationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;

+ (void) fetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context;

+ (void) tmpAddLocation: (CLLocation *) location inManagedObjectContext: (NSManagedObjectContext *) context;

@end
