//
//  Observation+Observation_helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/8/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation.h"
#import "NSManagedObjectContext+Extra.h"
#import <CoreLocation/CoreLocation.h>
#import <GeoPoint.h>

@interface Observation (helper)

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) initializeNewObservationWithLocation: (GeoPoint *) location;

- (CLLocation *) location;

- (NSString *) sectionName;

+ (Observation*) observationForJson: (NSDictionary *) json;

+ (NSOperation*) operationToPullObservations:(void (^) (BOOL success)) complete;
+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)()) success failure: (void (^)()) failure;

@end
