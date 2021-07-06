//
//  User+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface User (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *active;
@property (nullable, nonatomic, retain) NSString *avatarUrl;
@property (nullable, nonatomic, retain) NSNumber *currentUser;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *iconUrl;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *phone;
@property (nullable, nonatomic, retain) id recentEventIds;
@property (nullable, nonatomic, retain) NSString *remoteId;
@property (nullable, nonatomic, retain) NSString *username;
@property (nullable, nonatomic, retain) Location *location;
@property (nullable, nonatomic, retain) NSSet<Observation *> *observations;
@property (nullable, nonatomic, retain) Role *role;
@property (nullable, nonatomic, retain) NSSet<Team *> *teams;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addObservationsObject:(Observation *)value;
- (void)removeObservationsObject:(Observation *)value;
- (void)addObservations:(NSSet<Observation *> *)values;
- (void)removeObservations:(NSSet<Observation *> *)values;

- (void)addTeamsObject:(Team *)value;
- (void)removeTeamsObject:(Team *)value;
- (void)addTeams:(NSSet<Team *> *)values;
- (void)removeTeams:(NSSet<Team *> *)values;

@end

NS_ASSUME_NONNULL_END
