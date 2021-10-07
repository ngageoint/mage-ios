//
//  Observation.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "SFGeometry.h"
#import "SFPoint.h"

extern NSString * _Nonnull const kObservationErrorStatusCode;
extern NSString * _Nullable const kObservationErrorDescription;
extern NSString * _Nullable const kObservationErrorMessage;

@class Attachment, User, ObservationImportant, ObservationFavorite;

NS_ASSUME_NONNULL_BEGIN

@interface Observation : NSManagedObject

+ (NSURLSessionDataTask *) operationToPullInitialObservationsWithSuccess:(void (^) (void)) success failure: (void(^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPullObservationsWithSuccess:(void (^) (void)) success failure: (void(^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPushObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPushFavorite:(ObservationFavorite *) favorite success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPushImportant:(ObservationImportant *) important success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSDate *) fetchLastObservationDateInContext:(NSManagedObjectContext *) context;

+ (Observation *) observationWithGeometry:(nullable SFGeometry *) geometry andAccuracy: (CLLocationAccuracy) accuracy andProvider: (NSString *) provider andDelta: (double) delta inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext;
+ (Observation *) createObservation:(NSDictionary *) feature inContext:(NSManagedObjectContext *) localContext;
+ (BOOL) checkIfRectangle: (NSArray<SFPoint *> *) points;

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) addTransientAttachment: (Attachment *) attachment;
- (NSMutableArray *) transientAttachments;

- (void) shareObservationForViewController:(UIViewController *) viewController;

- (CLLocation *) location;

- (SFGeometry *) getGeometry;
- (void) setGeometry: (nullable SFGeometry *) geometry;

- (Boolean) isDirty;
- (Boolean) isImportant;
- (Boolean) isDeletableByCurrentUser;
- (Boolean) currentUserCanUpdateImportant;
- (Boolean) hasValidationError;
- (NSString *) errorMessage;

- (NSIndexSet *) getFormsToBeDeleted;
- (void) clearFormsToBeDeleted;
- (void) addFormToBeDeleted: (NSInteger) formIndex;
- (void) removeFormToBeDeleted: (NSInteger) formIndex;

- (nullable NSDictionary *) getPrimaryObservationForm;
- (NSDictionary *) getPrimaryEventForm;
- (NSString *) getPrimaryField;
- (NSString *) getSecondaryField;
- (NSString *) primaryFieldText;
- (NSString *) secondaryFieldText;
- (NSString *) primaryFeedFieldText;
- (NSString *) secondaryFeedFieldText;
+ (NSString *) fieldValueText:(id) value field:(NSDictionary *) field;

- (void) toggleFavoriteWithCompletion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (NSDictionary *) getFavoritesMap;

- (void) flagImportantWithDescription:(NSString *) description completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (void) removeImportantWithCompletion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (void) deleteObservationWithCompletion: (nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;

@end

NS_ASSUME_NONNULL_END

#import "Observation+CoreDataProperties.h"
