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
    id dirty = [json objectForKey:@"dirty"];
    if (dirty != nil) {
        [self setDirty:[NSNumber numberWithBool:[dirty boolValue]]];
    } else {
        [self setDirty:[NSNumber numberWithBool:NO]];
    }
    [self setLocalPath: [json objectForKey:@"localPath"]];
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;
    NSString *dateString = [json objectForKey:@"lastModified"];
    if (dateString != nil) {
        NSDate *date = [dateFormat dateFromString:dateString];
        [self setLastModified:date];
    } else {
        [self setLastModified:[NSDate date]];
    }
    return self;
}

+ (id) attachmentForJson: (NSDictionary *) json  {
    return [Attachment attachmentForJson:json inContext:[NSManagedObjectContext defaultManagedObjectContext]];
}

+ (id) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context  {
    return [Attachment attachmentForJson:json inContext:[NSManagedObjectContext defaultManagedObjectContext] insertIntoContext:nil];
}

+ (id) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context insertIntoContext: (NSManagedObjectContext *) insertContext  {
    
    Attachment *attachment = [[Attachment alloc] initWithEntity:[NSEntityDescription entityForName:@"Attachment" inManagedObjectContext:context] insertIntoManagedObjectContext:insertContext];
    
    [attachment populateObjectFromJson:json];
    
    return attachment;
}


@end
