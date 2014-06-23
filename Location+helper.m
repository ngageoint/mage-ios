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

+ (id) initWithJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Location *location = (Location *) [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
    
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
    
    return location;
}

+ (void) fetchLocationsWithManagedObjectContext: (NSManagedObjectContext *) context {
	NSLog(@"Trying to fetch locations from server");
	
    HttpManager *http = [HttpManager singleton];
	// TODO need to pull server url from somewhere
    NSString *url = [NSString stringWithFormat:@"%@/%@", @"https://magetpm.***REMOVED***", @"api/locations/users"];
    [http.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Location JSON: %@", responseObject);
        NSArray *locations = (NSArray *) responseObject;
        
        for (id location in locations) {
            Location *l = [Location initWithJson:location inManagedObjectContext:context];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
