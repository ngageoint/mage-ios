//
//  Location+helper.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Location.h"
#import "Geometry.h"
#import <CoreLocation/CoreLocation.h>

@interface Location (helper)

+ (Location *) locationForJson: (NSDictionary *) json;

-(CLLocation *) location;

- (NSString *) sectionName;

- (void) populateLocationFromJson:(NSArray *) locations;

+ (NSOperation *) operationToPullLocations:(void (^) (BOOL success)) complete;

@property (nonatomic, retain) Geometry* geometry;

@end
