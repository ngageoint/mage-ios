//
//  ObservationImportant+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationImportant.h"
#import "NSDate+Iso8601.h"

@implementation ObservationImportant


+ (ObservationImportant *) importantForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    ObservationImportant *important = [ObservationImportant MR_createEntityInContext:context];
    [important updateImportantForJson:json];
    
    return important;
}

- (void) updateImportantForJson: (NSDictionary *) json {
    self.dirty = [NSNumber numberWithBool:NO];
    self.important = [NSNumber numberWithBool:YES];
    self.userId = [json objectForKey:@"userId"];
    self.timestamp = [NSDate dateFromIso8601String:[json objectForKey:@"timestamp"]];
    self.reason = [json objectForKey:@"description"];
}


@end
