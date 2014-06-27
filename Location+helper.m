//
//  Location+helper.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Location+helper.h"

#import <CoreLocation/CoreLocation.h>
#import "User+helper.h"
#import "GeoPoint.h"

@implementation Location (helper)

+ (Location *) locationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
	NSArray *locations = [json objectForKey:@"locations"];
	if (!locations.count) return nil;

	Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
	[location updateLocationsForUserId:[json objectForKey:@"user"] locations:locations];
	
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

@end
