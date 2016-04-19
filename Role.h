//
//  Role.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

NS_ASSUME_NONNULL_BEGIN

@interface Role : NSManagedObject

+ (Role *) insertRoleForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;
+ (NSOperation *) operationToFetchRolesWithSuccess:(void (^)()) success
                                           failure:(void (^)(NSError *error)) failure;

- (void) updateUserForJson: (NSDictionary *) json;

@end

NS_ASSUME_NONNULL_END

#import "Role+CoreDataProperties.h"
