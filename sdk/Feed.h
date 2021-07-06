//
//  Feed+CoreDataClass.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FeedItem, Event, NSObject;

NS_ASSUME_NONNULL_BEGIN

@interface Feed : NSManagedObject

+ (NSArray <Feed *>*) getMappableFeeds: (NSNumber *) eventId;
+ (NSArray <Feed *>*) getEventFeeds: (NSNumber *) eventId;
+ (NSMutableArray <NSString *>*) populateFeedsFromJson: (NSArray *) feeds inEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context;
+ (NSString *) addFeedFromJson: (NSDictionary *) feed inEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context;
+ (NSMutableArray <NSNumber *>*) populateFeedItemsFromJson: (NSArray *) feedItems inFeedId: (NSString *) feedId inContext: (NSManagedObjectContext *) context;
+ (NSString *) feedIdFromJson:(NSDictionary *) json;
+ (NSURLSessionDataTask *) operationToPullFeedsForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToPullFeedItemsForFeed: (NSString *) feedId inEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure;
+ (void) refreshFeedsForEvent:(NSNumber *)eventId;
+ (void) pullFeedItemsForFeed:(NSString *) feedId inEvent:(NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure;
- (nullable NSURL *) iconURL;
- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId withTag: (NSNumber *) tag;
@end

NS_ASSUME_NONNULL_END

#import "Feed+CoreDataProperties.h"
