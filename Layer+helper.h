//
//  Layer+helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Layer.h"

@interface Layer (helper)

- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId;
+ (NSOperation *) operationToPullLayersForEvent: (NSNumber *) eventId success: (void (^)()) success failure: (void (^)(NSError *)) failure;
+ (void) refreshLayersForEvent: (NSNumber *) eventId;

@end
