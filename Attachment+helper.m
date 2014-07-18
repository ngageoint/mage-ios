//
//  Attachment+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Attachment+helper.h"

@implementation Attachment (helper)

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setContentType:[json objectForKey:@"contentType"]];
    [self setUrl:[json objectForKey:@"url"]];
    [self setName: [json objectForKey:@"name"]];
    [self setSize: [json objectForKey:@"size"]];
    return self;
}

+ (id) attachmentForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    
    Attachment *attachment = [[Attachment alloc] initWithEntity:[NSEntityDescription entityForName:@"Attachment" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    
    [attachment populateObjectFromJson:json];
    
    return attachment;
}


@end
