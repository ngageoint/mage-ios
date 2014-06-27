//
//  LocationResource.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocationResource.h"
#import "Location+helper.h"
#import <AFNetworking.h>
#import "HttpManager.h"

@implementation LocationResource

+ (void) fetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *serverUrl = [defaults URLForKey:@"serverUrl"];
	NSURL *url = [serverUrl URLByAppendingPathComponent:@"api/locations/users"];
	
	NSLog(@"Trying to fetch locations from server %@", url);
	
    HttpManager *http = [HttpManager singleton];
    [http.manager GET:[url absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id userLocations) {
		// Get the user ids to query
		NSMutableArray *userIds = [[NSMutableArray alloc] init];
		for (NSDictionary *userLocation in userLocations) {
			[userIds addObject:[userLocation objectForKey:@"user"]];
		}
		
		// Create the fetch request to get all users IDs from server response.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
		[fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(userId IN %@)", userIds]];
		NSError *error;
		NSArray *usersMatchingIDs = [context executeFetchRequest:fetchRequest error:&error];
		NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
		for (Location* location in usersMatchingIDs) {
			[userIdMap setObject:location forKey:location.userId];
		}
		
		for (NSDictionary *userLocation in userLocations) {
			// pull from query map
			NSString *userId = [userLocation objectForKey:@"user"];
			Location *location = [userIdMap objectForKey:userId];
			if (location == nil) {
				// not in core data yet need to create a new managed object
				NSLog(@"Inserting new user location into database");
				location = [Location locationForJson:userLocation inManagedObjectContext:context];
			} else {
				// already exists in core data, lets update the object we have
				NSLog(@"Updating user location in the database");
				[location updateLocationsForUserId:location.userId locations:[userLocation objectForKey:@"locations"]];
			}
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


@end
