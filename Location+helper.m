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

+ (id) locationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
	Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
    
	[location setUserId:[json objectForKey:@"user"]];
	
	NSArray *jsonLocations = [json objectForKey:@"locations"];
	for (NSDictionary* jsonLocation in jsonLocations) {
		[location setRemoteId:[jsonLocation objectForKey:@"_id"]];
		[location setType:[jsonLocation objectForKey:@"type"]];
		
		NSDictionary *properties = [jsonLocation objectForKey: @"properties"];
		for (NSString* key in properties) {
			NSLog(@"property json is: %@ value is: %@", key, properties[key]);
			if ([key isEqualToString:@"timestamp"]) {
				NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
				[dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
				NSDate *date = [dateFormat dateFromString:properties[key]];
				[location setTimestamp:date];
			}
			
			LocationProperty *property = [LocationProperty initWithKey:key andValue:properties[key] inManagedObjectContext:context];
			[location addPropertiesObject:property];
		}
	}
	
	[context insertObject:location];
	
    return location;
}

- (void) updateLocationForJson: (NSDictionary *) json {
	
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
				location = [Location locationForJson:jsonLocation inManagedObjectContext:context];
			} else {
				// already exists in core data, lets update the object we have
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
