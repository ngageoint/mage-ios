//
//  Team+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 3/11/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Team+helper.h"
#import "User+helper.h"

@implementation Team (helper)

+ (Team *) insertTeamForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    Team *team = [Team MR_createEntityInContext:context];
    [team updateTeamForJson:json inManagedObjectContext:context];
    return team;
}

- (void) updateTeamForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context{
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setTeamDescription:[json objectForKey:@"description"]];
    for (NSString *userId in [json objectForKey:@"users"]) {
        NSSet *filteredUsers = [self.users filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", userId]];
        if (filteredUsers.count == 0) {
            // see if the user exists
            User *u = [User MR_findFirstByAttribute:@"remoteId" withValue:userId];
            if (!u) {
                User *newUser = [User MR_createEntityInContext:context];
                [newUser setRemoteId:userId];
                [self addUsersObject:newUser];
            } else {
                [self addUsersObject:u];
            }
        }
    }
}

@end
