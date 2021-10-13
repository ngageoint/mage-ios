//
//  Team.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Team.h"
#import "User.h"

@implementation Team

+ (Team *) insertTeamForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    Team *team = [Team MR_createEntityInContext:context];
    [team updateTeamForJson:json inManagedObjectContext:context];
    return team;
}

- (void) updateTeamForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context{
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setTeamDescription:[json objectForKey:@"description"]];
    
    NSMutableSet *users = [[NSMutableSet alloc] init];
    for (NSString *userId in [json objectForKey:@"userIds"]) {
        // see if the user exists
        User *user = [User MR_findFirstByAttribute:@"remoteId" withValue:userId inContext:context];
        if (!user) {
            user = [User MR_createEntityInContext:context];
            [user setRemoteId:userId];
        }
        
        [users addObject:user];
    }
    
    [self setUsers:users];
}

@end
