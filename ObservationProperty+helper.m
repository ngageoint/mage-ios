//
//  ObservationProperty+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/9/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationProperty+helper.h"


@implementation ObservationProperty (ObservationProperty_helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    NSLog(@"Json is: %@", json);
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

+ (id) initWithKey: (NSString*) key andValue: (NSString*) value inManagedObjectContext: (NSManagedObjectContext *) context {
    ObservationProperty *property = (ObservationProperty*)[NSEntityDescription insertNewObjectForEntityForName:@"ObservationProperty" inManagedObjectContext:context];
    property.key = key;
    property.value = value;
    return property;
}


@end

