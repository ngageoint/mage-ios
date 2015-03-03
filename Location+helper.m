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
#import "HttpManager.h"
#import "MageServer.h"
#import <NSDate+DateTools.h>
#import "NSDate+Iso8601.h"

@implementation Location (helper)

//+ (Location *) locationForJson: (NSDictionary *) json {
//	NSArray *locations = [json objectForKey:@"locations"];
//	if (!locations.count) return nil;
//
//	Location *location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:[NSManagedObjectContext defaultManagedObjectContext]];
//	[location populateLocationFromJson:locations];
//	
//	return location;
//}

- (CLLocation *) location {
    GeoPoint *point = (GeoPoint *) self.geometry;
    return point.location;
}

- (NSString *) sectionName {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    return [dateFormatter stringFromDate:self.timestamp];
}

- (void) populateLocationFromJson:(NSArray *) locations {
	if (locations.count) {
		for (NSDictionary* jsonLocation in locations) {
			[self setRemoteId:[jsonLocation objectForKey:@"_id"]];
			[self setType:[jsonLocation objectForKey:@"type"]];
			
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
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


+ (NSOperation *) operationToPullLocations:(void (^) (BOOL success)) complete {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/locations/users"];
	NSLog(@"Trying to fetch locations from server %@", url);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    __block NSDate *lastLocationDate = [self fetchLastLocationDate];
    if (lastLocationDate != nil) {
        [parameters setObject:[lastLocationDate iso8601String] forKey:@"startDate"];
    }
	
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters:parameters error:nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id userLocations) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Fetched %lu locations from the server, saving to location storage", (unsigned long)[userLocations count]);
            User *currentUser = [User fetchCurrentUserInManagedObjectContext:localContext];
            
            // Get the user ids to query
            NSMutableArray *userIds = [[NSMutableArray alloc] init];
            for (NSDictionary *userLocation in userLocations) {
                [userIds addObject:[userLocation objectForKey:@"user"]];
            }
            
            NSArray *usersMatchingIDs = [User MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", userIds] inContext:localContext];
            NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
            for (User *user in usersMatchingIDs) {
                [userIdMap setObject:user forKey:user.remoteId];
            }
            
            BOOL newUserFound = NO;
            for (NSDictionary *userLocation in userLocations) {
                // pull from query map
                NSString *userId = [userLocation objectForKey:@"user"];
                NSArray *locations = [userLocation objectForKey:@"locations"];
                User *user = [userIdMap objectForKey:userId];
                if (user == nil && [locations count] != 0) {
                    NSLog(@"Could not find user for id");
                    newUserFound = YES;
                    NSDictionary *userDictionary = @{
                         @"_id": userId,
                         @"username": userId,
                         @"firstname": @"unknown",
                         @"lastname": @"unkown"
                     };
                    
                    user = [User MR_createEntityInContext:localContext];
                    user = [User insertUserForJson:userDictionary inManagedObjectContext:localContext];
                };
                if ([currentUser.remoteId isEqualToString:user.remoteId]) continue;
                
                Location *location = user.location;
                if (location == nil) {
                    // not in core data yet need to create a new managed object
                    location = [Location MR_createEntityInContext:localContext];
                    NSArray *locations = [userLocation objectForKey:@"locations"];
                    [location populateLocationFromJson:locations];
                    user.location = location;
                } else {
                    // already exists in core data, lets update the object we have
                    [location populateLocationFromJson:locations];
                }
            }
            
            if (newUserFound) {
                // For now if we find at least one new user let just go grab the users again
                [[User operationToFetchUsers] start];
            }
        }];
        
        complete(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
    }];
    
    return operation;
}

+ (NSDate *) fetchLastLocationDate {
    NSDate *date = nil;
    Location *location = [Location MR_findFirstOrderedByAttribute:@"timestamp" ascending:NO];
    if (location) {
        date = location.timestamp;
    }
        
    return date;
}

- (NSString *)sectionIdentifier {
    return [self timestamp].timeAgoSinceNow;
}


@end
