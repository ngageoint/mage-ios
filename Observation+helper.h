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

@interface Observation (Observation_helper)

- (id) populateObjectFromJson: (NSDictionary *) json;

+ (Observation*) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;

+ (void) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context;

@end
