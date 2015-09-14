//
//  NSDate+display.m
//  MAGE
//
//  Created by William Newman on 9/11/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "NSDate+display.h"

@implementation NSDate (display)

static NSDateFormatter *dateDisplayFormatter;

- (NSString *) formattedDisplayDate {
    if (dateDisplayFormatter == nil) {
        dateDisplayFormatter = [[NSDateFormatter alloc] init];
        [dateDisplayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateDisplayFormatter setDateFormat:@"yyyy-MM-dd h:mm:ss a"];
    }
    
    return [dateDisplayFormatter stringFromDate:self];
}


@end
