//
//  Location+helper.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Location+helper.h"
#import <AFNetworking.h>
#import "HttpManager.h"
#import "LocationProperty+helper.h"


@implementation Location (helper)

+ (void) locationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
	NSArray *jsonLocations = [json objectForKey:@"locations"];
	if (!jsonLocations.count) return;
	
	Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
	
	[location setUserId:[json objectForKey:@"user"]];
	for (NSDictionary* jsonLocation in jsonLocations) {
		[location setRemoteId:[jsonLocation objectForKey:@"_id"]];
		[location setType:[jsonLocation objectForKey:@"type"]];
		
		NSDictionary *properties = [jsonLocation objectForKey: @"properties"];
		[location setProperties:properties];
		
		for (NSString* key in properties) {
			NSLog(@"property json is: %@ value is: %@", key, properties[key]);
			if ([key isEqualToString:@"timestamp"]) {
				NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
				[dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'sss'Z'"];
				NSDate *date = [dateFormat dateFromString:properties[key]];
				[location setTimestamp:date];
			}
		}

	}
	
	[context insertObject:location];
}

- (void) updateLocationForJson: (NSDictionary *) json {
	NSArray *jsonLocations = [json objectForKey:@"locations"];
	NSDictionary *properties = [self properties];
	
	if (jsonLocations.count) {
		for (NSDictionary* jsonLocation in jsonLocations) {
			NSDictionary *properties = [jsonLocation objectForKey: @"properties"];
			
			[self setProperties:properties];
			for (NSString* key in properties) {
				NSLog(@"property json is: %@ value is: %@", key, properties[key]);
				if ([key isEqualToString:@"timestamp"]) {
					NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
					[dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
					NSString * dateString = properties[key];
					NSDate *date = [dateFormat dateFromString:properties[key]];
					[self setTimestamp:date];
				}
			}
		}
	} else {
		// delete user record from core data
	}
}

+ (void) fetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *serverUrl = [defaults URLForKey:@"serverUrl"];
	NSURL *url = [serverUrl URLByAppendingPathComponent:@"api/locations/users"];
	
	NSLog(@"Trying to fetch locations from server %@", url);
	
    HttpManager *http = [HttpManager singleton];
    [http.manager GET:[url absoluteString] parameters:nil success:^(AFHTTPRequestOperation *operation, id jsonLocations) {
		// Get the user ids to query
		NSMutableArray *userIds = [[NSMutableArray alloc] init];
		for (NSDictionary *jsonLocation in jsonLocations) {
			[userIds addObject:[jsonLocation objectForKey:@"user"]];
		}
		
		// Create the fetch request to get all users IDs from server response.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
		[fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(userId IN %@)", userIds]];
		NSError *error;
		NSArray *usersMatchingIDs = [context executeFetchRequest:fetchRequest error:&error];
		NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
		for (Location* location in usersMatchingIDs) {
			[userIdMap setObject:location forKey:[location  userId]];
		}
		
		for (NSDictionary *jsonLocation in jsonLocations) {
			// pull from query map
			NSString *userId = [jsonLocation objectForKey:@"user"];
			Location *location = [userIdMap objectForKey:userId];
			if (location == nil) {
				// not in core data yet need to create a new managed object
				NSLog(@"Inserting new user location into database");
				[Location locationForJson:jsonLocation inManagedObjectContext:context];
			} else {
				// already exists in core data, lets update the object we have
				NSLog(@"Updating user location in the database");
				[location updateLocationForJson:jsonLocation];
			}
			
			NSError *error = nil;
			if (! [context save:&error]) {
				NSLog(@"Error inserting location: %@", error);
			}
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
