//
//  Location+helper.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <AFNetworking.h>
#import "Location+helper.h"
#import "HttpManager.h"
#import "GeoPoint.h"

@implementation Location (helper)

+ (void) tmpAddLocation: (CLLocation *) location inManagedObjectContext: (NSManagedObjectContext *) context {
	Location *l = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
	
	[l setGeometry:[[GeoPoint alloc] initWithLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]]];
	[context insertObject:l];
	
	NSError *error = nil;
	if (! [context save:&error]) {
		NSLog(@"Error inserting location: %@", error);
	}
}

+ (Location *) locationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
	NSArray *locations = [json objectForKey:@"locations"];
	if (!locations.count) return nil;
	
	Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
	[location updateLocationsForUserId:[json objectForKey:@"user"] locations:locations];

	[context insertObject:location];
	
	return location;
}

- (void) updateLocationsForUserId:(NSString *) userId locations: (NSArray *) locations {
	if (locations.count) {
		[self setUserId:userId];
		
		for (NSDictionary* jsonLocation in locations) {
			[self setRemoteId:[jsonLocation objectForKey:@"_id"]];
			[self setType:[jsonLocation objectForKey:@"type"]];
			
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
			NSDate *date = [dateFormat dateFromString:[jsonLocation valueForKeyPath:@"properties.timestamp"]];
			[self setTimestamp:date];
			[self setProperties:[jsonLocation valueForKeyPath:@"properties"]];
			
			NSArray *coordinates = [jsonLocation valueForKeyPath:@"geometry.coordinates"];
			CLLocation *location = [[CLLocation alloc]
				initWithCoordinate:CLLocationCoordinate2DMake([[coordinates objectAtIndex: 1] floatValue], [[coordinates objectAtIndex: 0] floatValue])
				altitude:[[jsonLocation valueForKeyPath:@"properties.altitude"] floatValue]
				horizontalAccuracy:[[jsonLocation valueForKeyPath:@"properties.altitude"] floatValue]
				verticalAccuracy:[[jsonLocation valueForKeyPath:@"properties.accuracy"] floatValue]
				course:[[jsonLocation valueForKeyPath:@"properties.bearing"] floatValue]
				speed:[[jsonLocation valueForKeyPath:@"properties.speed"] floatValue]
				timestamp:date];
			
			[self setGeometry:[[GeoPoint alloc] initWithLocation:location]];
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
			[userIdMap setObject:location forKey:[location  userId]];
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
				[location updateLocationsForUserId:userId locations:[userLocation objectForKey:@"locations"]];
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
