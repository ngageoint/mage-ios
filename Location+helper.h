//
//  Location+helper.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Location.h"

@interface Location (helper)

+ (void) locationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;

+ (void) fetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context;

@end
