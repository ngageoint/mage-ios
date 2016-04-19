//
//  Observation.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GeoPoint.h"

@class Attachment, User;

NS_ASSUME_NONNULL_BEGIN

@interface Observation : NSManagedObject

+ (Observation *) observationWithLocation:(GeoPoint *) location inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext;

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) addTransientAttachment: (Attachment *) attachment;
- (NSMutableArray *) transientAttachments;

- (CLLocation *) location;

- (NSString *) sectionName;

+ (NSOperation*) operationToPullObservationsWithSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure;
+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;

@end

NS_ASSUME_NONNULL_END

#import "Observation+CoreDataProperties.h"
