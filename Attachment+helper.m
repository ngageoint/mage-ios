//
//  Attachment+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Attachment+helper.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation Attachment (helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setContentType:[json objectForKey:@"contentType"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setName: [json objectForKey:@"name"]];
    [self setSize: [json objectForKey:@"size"]];
    [self setDirty:[NSNumber numberWithBool:NO]];
    return self;
}

+ (id) attachmentForJson: (NSDictionary *) json  {
    
    Attachment *attachment = [[Attachment alloc] initWithEntity:[NSEntityDescription entityForName:@"Attachment" inManagedObjectContext:[NSManagedObjectContext defaultManagedObjectContext]] insertIntoManagedObjectContext:nil];
    
    [attachment populateObjectFromJson:json];
    
    return attachment;
}


@end
