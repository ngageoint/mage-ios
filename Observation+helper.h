//
//  Observation+Observation_helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/8/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation.h"
#import <CoreLocation/CoreLocation.h>
#import "GeoPoint.h"
#import "Attachment.h"

@interface Observation (helper)

+ (Observation *) observationWithLocation:(GeoPoint *) location inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext;

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) addTransientAttachment: (Attachment *) attachment;
- (NSMutableArray *) transientAttachments;

- (CLLocation *) location;

- (NSString *) sectionName;

+ (NSOperation*) operationToPullObservations:(void (^) (BOOL success)) complete;
+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)()) success failure: (void (^)()) failure;

@end
