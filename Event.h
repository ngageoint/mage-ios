//
//  Event.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;
@class Team;

NS_ASSUME_NONNULL_BEGIN

@interface Event : NSManagedObject

extern NSString * const MAGEEventsFetched;
+ (NSOperation *) operationToFetchEventsWithSuccess: (void (^)()) success failure: (void (^)(NSError *)) failure;
+ (void) sendRecentEvent;
+ (Event *) getCurrentEvent;
- (BOOL) isUserInEvent: (User *) user;

@end

NS_ASSUME_NONNULL_END

#import "Event+CoreDataProperties.h"
