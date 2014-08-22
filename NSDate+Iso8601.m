//
//  NSDate+Iso8601.m
//  mage-ios-sdk
//
//  Created by William Newman on 8/20/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "NSDate+Iso8601.h"

@implementation NSDate (Iso8601)

static NSDateFormatter* dateFormatter = nil;

- (NSString *) iso8601String {
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    }
    
    return [dateFormatter stringFromDate:self];
}

@end
