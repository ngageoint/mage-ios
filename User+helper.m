//
//  User+helper.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User+helper.h"
#import "HttpManager.h"
#import "MageServer.h"

@implementation User (helper)

static User *currentUser = nil;

+ (User *) insertUserForJson: (NSDictionary *) json myself:(BOOL) myself inManagedObjectContext:(NSManagedObjectContext *) context {
    User *user = [User MR_createInContext:context];
    [user setCurrentUser:[NSNumber numberWithBool:myself]];
    [user updateUserForJson:json];
    
    return user;
}

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
	return [User insertUserForJson:json myself:NO inManagedObjectContext:context];
}

+ (User *) fetchCurrentUserInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    return [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"currentUser = %@", [NSNumber numberWithBool:YES]] inContext:managedObjectContext];
}

+ (User *) fetchUserForId:(NSString *) userId {
    return [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId = %@", userId]];
}

- (void) updateUserForJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"_id"]];
    [self setUsername:[json objectForKey:@"username"]];
    [self setEmail:[json objectForKey:@"email"]];
    [self setName:[NSString stringWithFormat:@"%@ %@", [json objectForKey:@"firstname"], [json objectForKey:@"lastname"]]];
    
    NSArray *phones = [json objectForKey:@"phones"];
    if (phones != nil && [phones count] > 0) {
        NSDictionary *phone = [phones objectAtIndex:0];
        [self setPhone:[phone objectForKey:@"number"]];
    }
    
    [self setIconUrl:[json objectForKey:@"iconUrl"]];
    [self setAvatarUrl:[json objectForKey:@"avatarUrl"]];
}

+ (NSOperation *) operationToFetchUsers {
	NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/users"];
	
	NSLog(@"Trying to fetch users from server %@", url);
	
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id users) {
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            // Get the user ids to query
            NSMutableArray *userIds = [[NSMutableArray alloc] init];
            for (NSDictionary *userJson in users) {
                [userIds addObject:[userJson objectForKey:@"_id"]];
            }
            
            NSArray *usersMatchingIDs = [User MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", userIds] inContext:localContext];
            NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
            for (User* user in usersMatchingIDs) {
                [userIdMap setObject:user forKey:user.remoteId];
            }
            
            for (NSDictionary *userJson in users) {
                // pull from query map
                NSString *userId = [userJson objectForKey:@"_id"];
                User *user = [userIdMap objectForKey:userId];
                if (user == nil) {
                    // not in core data yet need to create a new managed object
                    NSLog(@"Inserting new user into database");
                    [User insertUserForJson:userJson inManagedObjectContext:localContext];
                } else {
                    // already exists in core data, lets update the object we have
                    NSLog(@"Updating user location in the database");
                    [user updateUserForJson:userJson];
                }
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}

@end
