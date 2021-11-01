//
//  ImageryLayer+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/1/19.
//  Copyright © 2019 National Geospatial-Intelligence Agency. All rights reserved.
//
//

#import "ImageryLayer.h"

@implementation ImageryLayer

- (id) populateObjectFromJson: (NSDictionary *) json withEventId: (NSNumber *) eventId {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setType:[json objectForKey:@"type"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setEventId:eventId];
    [self setFormat:[json objectForKey:@"format"]];
    [self setOptions:[json objectForKey:@"wms"]];
    [self setIsSecure:[[json objectForKey:@"url"] hasPrefix:@"https"]];
    return self;
}

@end
