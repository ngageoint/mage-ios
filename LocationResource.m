//
//  LocationResource.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocationResource.h"
#import "Location+helper.h"
#import "User+helper.h"
#import <AFNetworking.h>
#import "HttpManager.h"

@implementation LocationResource

+ (NSOperation *) operationToFetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *serverUrl = [defaults URLForKey:@"serverUrl"];
	NSString *url = [NSString stringWithFormat:@"%@/%@", serverUrl, @"api/locations/users"];
	NSLog(@"Trying to fetch locations from server %@", url);

	
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id userLocations) {

		// Get the user ids to query
		NSMutableArray *userIds = [[NSMutableArray alloc] init];
		for (NSDictionary *userLocation in userLocations) {
			[userIds addObject:[userLocation objectForKey:@"user"]];
		}
		
		// Create the fetch request to get all users IDs from server response.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:context]];
		[fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(remoteId IN %@)", userIds]];
		NSError *error;
		NSArray *usersMatchingIDs = [context executeFetchRequest:fetchRequest error:&error];
		NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
		for (User *user in usersMatchingIDs) {
			[userIdMap setObject:user forKey:user.remoteId];
		}
		
		for (NSDictionary *userLocation in userLocations) {
			// pull from query map
			NSString *userId = [userLocation objectForKey:@"user"];
			User *user = [userIdMap objectForKey:userId];
			if (user == nil) continue;
			
			Location *location = user.location;
			if (location == nil) {
				// not in core data yet need to create a new managed object
				NSLog(@"Inserting new user location into database");
				location = [Location locationForJson:userLocation inManagedObjectContext:context];
				user.location = location;
			} else {
				// already exists in core data, lets update the object we have
				NSLog(@"Updating user location in the database");
				[location populateLocationFromJson:[userLocation objectForKey:@"locations"]];
			}
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}


@end
