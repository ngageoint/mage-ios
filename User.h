//
//  User.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location, Observation, Role, Team;

NS_ASSUME_NONNULL_BEGIN

@interface User : NSManagedObject

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;
+ (User *) fetchUserForId:(NSString *) userId inManagedObjectContext: (NSManagedObjectContext *) context;
+ (User *) fetchCurrentUserInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
+ (NSURLSessionDataTask *) operationToFetchMyselfWithSuccess: (void(^)(void)) success failure: (void(^)(NSError *)) failure;
+ (NSURLSessionDataTask *) operationToFetchUsersWithSuccess: (void(^)(void)) success failure: (void(^)(NSError *)) failure;

- (void) updateUserForJson: (NSDictionary *) json;
- (BOOL) hasEditPermission;
@end

NS_ASSUME_NONNULL_END

#import "User+CoreDataProperties.h"
