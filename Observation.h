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

@class Attachment, User, ObservationImportant, ObservationFavorite;

NS_ASSUME_NONNULL_BEGIN

@interface Observation : NSManagedObject

+ (NSOperation*) operationToPullObservationsWithSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure;
+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSOperation *) operationToPushFavorite:(ObservationFavorite *) favorite success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSOperation *) operationToPushImportant:(ObservationImportant *) important success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;

+ (Observation *) observationWithLocation:(GeoPoint *) location inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext;

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) addTransientAttachment: (Attachment *) attachment;
- (NSMutableArray *) transientAttachments;

- (void) shareObservationForViewController:(UIViewController *) viewController;

- (CLLocation *) location;

- (NSString *) sectionName;

- (Boolean) isImportant;

- (void) toggleFavoriteWithCompletion:(void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (NSDictionary *) getFavoritesMap;

- (void) flagImportantWithDescription:(NSString *) description completion:(void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (void) removeImportantWithCompletion:(void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;

@end

NS_ASSUME_NONNULL_END

#import "Observation+CoreDataProperties.h"
