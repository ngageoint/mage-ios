//
//  Event+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Event.h"

NS_ASSUME_NONNULL_BEGIN

@interface Event (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *eventDescription;
@property (nullable, nonatomic, retain) id forms;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *recentSortOrder;
@property (nullable, nonatomic, retain) NSNumber *remoteId;
@property (nullable, nonatomic, retain) NSNumber *maxObservationForms;
@property (nullable, nonatomic, retain) NSNumber *minObservationForms;
@property (nullable, nonatomic, retain) NSSet<Team *> *teams;
@property (nullable, nonatomic, retain) NSSet<Feed *> *feeds;
@property (nullable, nonatomic, retain) NSDictionary *acl;

@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addTeamsObject:(Team *)value;
- (void)removeTeamsObject:(Team *)value;
- (void)addTeams:(NSSet<Team *> *)values;
- (void)removeTeams:(NSSet<Team *> *)values;
- (void)addFeedsObject:(Team *)value;
- (void)removeFeedsObject:(Team *)value;
- (void)addFeeds:(NSSet<Team *> *)values;
- (void)removeFeeds:(NSSet<Team *> *)values;

@end

NS_ASSUME_NONNULL_END
