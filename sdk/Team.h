//
//  Team.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event, User;

NS_ASSUME_NONNULL_BEGIN

@interface Team : NSManagedObject

- (void) updateTeamForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;
+ (Team *) insertTeamForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;

@end

NS_ASSUME_NONNULL_END

#import "Team+CoreDataProperties.h"
