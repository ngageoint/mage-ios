//
//  Attachment+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Attachment+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation Attachment (helper)

+ (Attachment *) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context {
    Attachment *attachment = [Attachment MR_createEntityInContext:context];
    [attachment populateFromJson:json];
    return attachment;
}

- (id) populateFromJson: (NSDictionary *) json {
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

@end
