//
//  Attachment+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Attachment+helper.h"
#import <MagicalRecord/MagicalRecord.h>
#import "NSDate+iso8601.h"

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

    NSString *dateString = [json objectForKey:@"lastModified"];
    if (dateString != nil) {
        NSDate *date = [NSDate dateFromIso8601String:dateString];
        [self setLastModified:date];
    } else {
        [self setLastModified:[NSDate date]];
    }
    return self;
}

- (NSURL *) sourceURL {
    if (self.localPath) {
        return [NSURL fileURLWithPath:self.localPath];
    } else {
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@", self.url, [defaults valueForKeyPath:@"loginParameters.token"]]];
    }
}

@end
