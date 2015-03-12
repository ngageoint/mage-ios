//
//  Team+helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 3/11/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Team.h"

@interface Team (helper)

- (void) updateTeamForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;
+ (Team *) insertTeamForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context;

@end
