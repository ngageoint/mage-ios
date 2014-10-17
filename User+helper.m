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

+ (User *) insertUserForJson: (NSDictionary *) json myself:(BOOL) myself inManagedObjectContext: (NSManagedObjectContext *) context {
	User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    [user setCurrentUser:[NSNumber numberWithBool:myself]];
	[user updateUserForJson:json inManagedObjectContext:context];
    
	return user;
}

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
	return [User insertUserForJson:json myself:NO inManagedObjectContext:context];
}

+ (User *) fetchCurrentUserForManagedObjectContext: (NSManagedObjectContext *) context {
    if (currentUser == nil) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:context]];
        [request setPredicate: [NSPredicate predicateWithFormat:@"currentUser = %@", [NSNumber numberWithBool:YES]]];
        [request setFetchLimit:1];
        
        NSError *error;
        NSArray *users = [context executeFetchRequest:request error:&error];
        
        if (error || users.count < 1) {
            NSLog(@"Error getting current user (myself) from database");
            return nil;
        }
        
        currentUser = [users objectAtIndex:0];
    }

    return currentUser;
}

+ (User *) fetchUserForId:(NSString *) userId  inManagedObjectContext: (NSManagedObjectContext *) context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:context]];
	[request setPredicate: [NSPredicate predicateWithFormat:@"remoteId = %@", userId]];
	[request setFetchLimit:1];
	
	NSError *error;
	NSArray *users = [context executeFetchRequest:request error:&error];
	
	if (error || users.count < 1) {
		NSLog(@"Error getting user from database for id: %@", userId);
		return nil;
	}
		
	return [users objectAtIndex:0];
}

- (void) updateUserForJson: (NSDictionary *) json  inManagedObjectContext:(NSManagedObjectContext *) context {
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
	
	NSError *error = nil;
	if (! [context save:&error]) {
		NSLog(@"Error updating User: %@", error);
	}
}

+ (NSOperation *) operationToFetchUsersWithManagedObjectContext: (NSManagedObjectContext *) context {
	NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseServerUrl], @"api/users"];
	
	NSLog(@"Trying to fetch users from server %@", url);
	
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id users) {
		// Get the user ids to query
		NSMutableArray *userIds = [[NSMutableArray alloc] init];
		for (NSDictionary *userJson in users) {
			[userIds addObject:[userJson objectForKey:@"_id"]];
		}
		
		// Create the fetch request to get all users IDs from server response.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:context]];
		[fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(remoteId IN %@)", userIds]];
		NSError *error;
		NSArray *usersMatchingIDs = [context executeFetchRequest:fetchRequest error:&error];
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
				user = [User insertUserForJson:userJson inManagedObjectContext:context];
			} else {
				// already exists in core data, lets update the object we have
				NSLog(@"Updating user location in the database");
				[user updateUserForJson:userJson inManagedObjectContext:context];
			}
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}

@end
