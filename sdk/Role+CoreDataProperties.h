//
//  Role+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Role.h"

NS_ASSUME_NONNULL_BEGIN

@interface Role (CoreDataProperties)

@property (nullable, nonatomic, retain) id permissions;
@property (nullable, nonatomic, retain) NSString *remoteId;
@property (nullable, nonatomic, retain) NSSet<User *> *users;

@end

@interface Role (CoreDataGeneratedAccessors)

- (void)addUsersObject:(User *)value;
- (void)removeUsersObject:(User *)value;
- (void)addUsers:(NSSet<User *> *)values;
- (void)removeUsers:(NSSet<User *> *)values;

@end

NS_ASSUME_NONNULL_END
