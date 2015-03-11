//
//  User+helper.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User.h"

@interface User (helper)

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;
+ (User *) insertUserForJson: (NSDictionary *) json myself:(BOOL) myself inManagedObjectContext:(NSManagedObjectContext *) context;
+ (User *) fetchUserForId:(NSString *) userId inManagedObjectContext: (NSManagedObjectContext *) context;
+ (User *) fetchCurrentUserInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
+ (NSOperation *) operationToFetchMyselfWithSuccess: (void(^)()) success failure: (void(^)(NSError *)) failure;
+ (NSOperation *) operationToFetchUsersWithSuccess: (void(^)()) success failure: (void(^)(NSError *)) failure;

- (void) updateUserForJson: (NSDictionary *) json;

@end
