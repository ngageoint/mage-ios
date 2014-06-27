//
//  UserResource.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "UserResource.h"

#import <AFNetworking.h>
#import "HttpManager.h"
#import "User+helper.h"

@implementation UserResource

+ (void) fetchUsersWithManagedObjectContext: (NSManagedObjectContext *) context {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *serverUrl = [defaults URLForKey:@"serverUrl"];
	NSURL *url = [serverUrl URLByAppendingPathComponent:@"api/users"];
	
	NSLog(@"Trying to fetch users from server %@", url);
	
    HttpManager *http = [HttpManager singleton];
    [http.manager GET:[url absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id users) {
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
}

@end
