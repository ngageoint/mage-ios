//
//  LocationProperty+helper.m
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/19/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocationProperty+helper.h"

@implementation LocationProperty (helper)

- (id) populateFromJson: (NSDictionary *) json {
    NSLog(@"Location Property JSON is: %@", json);
	//    [self setRemoteId:[json objectForKey:@"id"]];
	//    [self setUserId:[json objectForKey:@"userId"]];
	//    [self setDeviceId:[json objectForKey:@"deviceId"]];
	//
	//    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	//    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
	//    NSDate *date = [dateFormat dateFromString:[json objectForKey:@"lastModified"]];
	//    [self setLastModified:date];
	//    [self setUrl:[json objectForKey:@"url"]];
    return self;
}

+ (id) locationWithJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    LocationProperty *property =
		(LocationProperty *) [NSEntityDescription insertNewObjectForEntityForName:@"LocationProperty" inManagedObjectContext:context];
    [property populateFromJson:json];
	
    return property;
}

+ (id) initWithKey: (NSString*) key andValue: (NSString*) value inManagedObjectContext: (NSManagedObjectContext *) context {
    LocationProperty *property = (LocationProperty *) [NSEntityDescription insertNewObjectForEntityForName:@"LocationProperty" inManagedObjectContext:context];
    property.key = key;
    property.value = value;
	
    return property;
}

@end
