//
//  Feed+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "Feed.h"
//#import "FeedItem.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "MAGE-Swift.h"

//@class FeedItem;

@implementation Feed

- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId withTag: (NSNumber *) tag {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setTag:tag];
    [self setTitle:[json objectForKey:@"title"]];
    [self setSummary:[json objectForKey:@"summary"]];
    [self setConstantParams:[json objectForKey:@"constantParams"]];
    [self setVariableParams:[json objectForKey:@"variableParams"]];
    [self setUpdateFrequency:[[json objectForKey:@"updateFrequency"] objectForKey:@"seconds"]];
    [self setPullFrequency:[[json objectForKey:@"updateFrequency"] objectForKey:@"seconds"]];
    [self setMapStyle:[json objectForKey:@"mapStyle"]];
    [self setItemPropertiesSchema:[json objectForKey:@"itemPropertiesSchema"]];
    [self setItemPrimaryProperty:[json objectForKey:@"itemPrimaryProperty"]];
    [self setItemSecondaryProperty:[json objectForKey:@"itemSecondaryProperty"]];
    [self setItemTemporalProperty:[json objectForKey:@"itemTemporalProperty"]];
    [self setItemsHaveIdentity:[json objectForKey:@"itemsHaveIdentity"]];
    [self setItemsHaveSpatialDimension:[[json objectForKey:@"itemsHaveSpatialDimension"] boolValue] ];
    [self setEventId:eventId];
    return self;
}

- (nullable NSURL *) iconURL {
    NSString *urlString =[NSString stringWithFormat:@"%@/api/icons/%@/content", [MageServer baseURL], [((NSDictionary *)self.mapStyle) valueForKeyPath:@"icon.id"]];
    if (urlString != nil) {
        return [NSURL URLWithString:urlString];
    }
    return nil;
}

+ (NSString *) feedIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (NSArray <Feed *>*) getMappableFeeds: (NSNumber *) eventId {
    return [Feed MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(itemsHaveSpatialDimension == 1 AND eventId == %@)", eventId]];
}

+ (NSArray <Feed *>*) getEventFeeds: (NSNumber *) eventId {
    return [Feed MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(eventId == %@)", eventId]];
}

+ (NSString *) addFeedFromJson: (NSDictionary *) feed inEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context {
    NSMutableArray *selectedFeedsForEvent = [[NSUserDefaults.standardUserDefaults objectForKey:[NSString stringWithFormat:@"selectedFeeds-%@", eventId]] mutableCopy];
    if (selectedFeedsForEvent == nil) {
        selectedFeedsForEvent = [[NSMutableArray alloc] init];
    }
    NSUInteger count = [Feed MR_countOfEntities];
    NSString *remoteFeedId = [Feed feedIdFromJson:feed];
    Feed *f = [Feed MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteFeedId, eventId] inContext:context];
    if (f == nil) {
        f = [Feed MR_createEntityInContext:context];
        [selectedFeedsForEvent addObject:remoteFeedId];
    }
    
    [f populateObjectFromJson:feed withEventId:eventId withTag:[NSNumber numberWithUnsignedInteger: count]];
    
    [NSUserDefaults.standardUserDefaults setObject:selectedFeedsForEvent forKey:[NSString stringWithFormat:@"selectedFeeds-%@", eventId]];
    [NSUserDefaults.standardUserDefaults synchronize];
    return remoteFeedId;
}

+ (NSMutableArray <NSString *>*) populateFeedsFromJson: (NSArray *) feeds inEventId: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context {
    NSMutableArray *feedRemoteIds = [[NSMutableArray alloc] init];
    NSMutableArray *selectedFeedsForEvent = [[NSUserDefaults.standardUserDefaults objectForKey:[NSString stringWithFormat:@"selectedFeeds-%@", eventId]] mutableCopy];
    if (selectedFeedsForEvent == nil) {
        selectedFeedsForEvent = [[NSMutableArray alloc] init];
    }
    NSUInteger count = [Feed MR_countOfEntities];
    for (id feed in feeds) {
        NSString *remoteFeedId = [Feed feedIdFromJson:feed];
        [feedRemoteIds addObject:remoteFeedId];
        Feed *f = [Feed MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND eventId == %@)", remoteFeedId, eventId] inContext:context];
        if (f == nil) {
            f = [Feed MR_createEntityInContext:context];
            [selectedFeedsForEvent addObject:remoteFeedId];
        }
        
        [f populateObjectFromJson:feed withEventId:eventId withTag:[NSNumber numberWithUnsignedInteger: count]];
        count++;
    }
    [selectedFeedsForEvent filterUsingPredicate:[NSPredicate predicateWithFormat:@"self in %@", feedRemoteIds]];
    [NSUserDefaults.standardUserDefaults setObject:selectedFeedsForEvent forKey:[NSString stringWithFormat:@"selectedFeeds-%@", eventId]];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    return feedRemoteIds;
}

+ (NSMutableArray <NSNumber *>*) populateFeedItemsFromJson: (NSArray *) feedItems inFeedId: (NSString *) feedId inEvent: (NSNumber *) eventId inContext: (NSManagedObjectContext *) context {
    NSMutableArray *feedItemRemoteIds = [[NSMutableArray alloc] init];
    Feed *feed = [Feed MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", feedId, eventId] inContext:context];
    for (id feedItem in feedItems) {
        NSString *remoteFeedItemId = [FeedItem feedItemIdFromJsonWithJson:feedItem];
        [feedItemRemoteIds addObject:remoteFeedItemId];
        FeedItem *fi = [FeedItem MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@ AND feed == %@)", remoteFeedItemId, feed] inContext:context];
        if (fi == nil) {
            fi = [FeedItem MR_createEntityInContext:context];
        }
        [fi populateWithJson:feedItem feed:feed];
    }
    
    [FeedItem MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"(NOT (remoteId IN %@)) AND feed == %@", feedItemRemoteIds, feed] inContext:context];
    
    return feedItemRemoteIds;
}

+ (void) refreshFeedsForEvent:(NSNumber *)eventId {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *task = [Feed operationToPullFeedsForEvent:eventId success:^{
    } failure:^(NSError *error) {
    }];
    [manager addTask:task];
}

+ (void) pullFeedItemsForFeed:(NSString *) feedId inEvent:(NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *task = [Feed operationToPullFeedItemsForFeed:feedId inEvent:eventId success:success failure:failure];
    [manager addTask:task];
}

+ (NSURLSessionDataTask *) operationToPullFeedsForEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/feeds", [MageServer baseURL], eventId];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    __block NSArray *feedRemoteIds = nil;
    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            feedRemoteIds = [Feed populateFeedsFromJson:responseObject inEventId:eventId inContext:localContext];
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
                    [Feed MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"(NOT (remoteId IN %@)) AND eventId == %@", feedRemoteIds, eventId] inContext:localContext];
                    
                } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
                    NSArray *feeds = [Feed MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventId]];
                    for (Feed *feed in feeds) {
                        [Feed pullFeedItemsForFeed:feed.remoteId inEvent:eventId success:^{
                        } failure:^(NSError *error) {
                        }];
                    }
                    success();
                }];
            }
        }];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}

+ (NSURLSessionDataTask *) operationToPullFeedItemsForFeed: (NSString *) feedId inEvent: (NSNumber *) eventId success: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/feeds/%@/content", [MageServer baseURL], eventId, feedId];
    
    MageSessionManager *manager = [MageSessionManager sharedManager];
    NSURLSessionDataTask *task = [manager POST_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSArray *features = [responseObject mutableArrayValueForKeyPath:@"items.features"];
            [Feed populateFeedItemsFromJson:features inFeedId:feedId inEvent: eventId inContext:localContext];
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
                success();
            }
        }];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}

@end
