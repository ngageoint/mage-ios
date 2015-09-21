//
//  Team+helper.m
//  mage-ios-sdk
//
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
    for (NSString *userId in [json objectForKey:@"userIds"]) {
        NSLog(@"Thinking about adding user %@ to the team %@", userId, self.name);
        NSSet *filteredUsers = [self.users filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", userId]];
        if (filteredUsers.count == 0) {
            // see if the user exists
            User *user = [User MR_findFirstByAttribute:@"remoteId" withValue:userId inContext:context];
            if (!user) {
                User *newUser = [User MR_createEntityInContext:context];
                [newUser setRemoteId:userId];
                [self addUsersObject:newUser];
            } else {
                [self addUsersObject:user];
            }
        }
    }
}

@end
