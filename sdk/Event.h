//
//  Event.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Observation.h"

@class User;
@class Team;
@class Feed;

NS_ASSUME_NONNULL_BEGIN

@interface Event : NSManagedObject

extern NSString * const MAGEEventsFetched;
+ (NSURLSessionDataTask *) operationToFetchEventsWithSuccess: (void (^)(void)) success failure: (void (^)(NSError *)) failure;
+ (void) sendRecentEvent;
+ (Event *) getCurrentEventInContext:(NSManagedObjectContext *) context;
+ (Event *) getEventById: (id) eventId inContext: (NSManagedObjectContext *) context;
+ (NSFetchedResultsController *) caseInsensitiveSortFetchAll:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(nullable NSPredicate *)searchTerm groupBy:(nullable NSString *)groupingKeyPath inContext: (NSManagedObjectContext *) context;
- (BOOL) isUserInEvent: (User *) user;
- (NSDictionary *) formForObservation: (Observation *) observation;
- (NSDictionary *) formWithId: (long) id;
- (NSArray *) nonArchivedForms;

@end

NS_ASSUME_NONNULL_END

#import "Event+CoreDataProperties.h"
