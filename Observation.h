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
#import "WKBGeometry.h"
#import "WKBPoint.h"

extern NSString * _Nonnull const kObservationErrorStatusCode;
extern NSString * _Nullable const kObservationErrorDescription;
extern NSString * _Nullable const kObservationErrorMessage;

@class Attachment, User, ObservationImportant, ObservationFavorite;

NS_ASSUME_NONNULL_BEGIN

@interface Observation : NSManagedObject

+ (NSURLSessionDataTask *) operationToPullInitialObservationsWithSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPullObservationsWithSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPushObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPushFavorite:(ObservationFavorite *) favorite success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPushImportant:(ObservationImportant *) important success:(void (^)(id)) success failure: (void (^)(NSError *)) failure;

+ (Observation *) observationWithGeometry:(WKBGeometry *) geometry andAccuracy: (CLLocationAccuracy) accuracy andProvider: (NSString *) provider andDelta: (double) delta inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext;
+ (BOOL) checkIfRectangle: (NSArray<WKBPoint *> *) points;

- (id) populateObjectFromJson: (NSDictionary *) json;
- (void) addTransientAttachment: (Attachment *) attachment;
- (NSMutableArray *) transientAttachments;

- (void) shareObservationForViewController:(UIViewController *) viewController;

- (CLLocation *) location;

- (WKBGeometry *) getGeometry;
- (void) setGeometry: (WKBGeometry *) geometry;

- (Boolean) isDirty;
- (Boolean) isImportant;
- (Boolean) isDeletableByCurrentUser;
- (Boolean) currentUserCanUpdateImportant;
- (Boolean) hasValidationError;
- (NSString *) errorMessage;

- (NSDictionary *) getPrimaryForm;
- (NSString *) getPrimaryField;
- (NSString *) getSecondaryField;
- (NSString *) primaryFieldText;
- (NSString *) secondaryFieldText;

- (void) toggleFavoriteWithCompletion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (NSDictionary *) getFavoritesMap;

- (void) flagImportantWithDescription:(NSString *) description completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (void) removeImportantWithCompletion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
- (void) deleteObservationWithCompletion: (nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;

@end

NS_ASSUME_NONNULL_END

#import "Observation+CoreDataProperties.h"
