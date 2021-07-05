//
//  NSDate+display.m
//  mage-ios-sdk
//
//  Created by William Newman on 3/12/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "NSDate+display.h"

NSString * const kgmtTimeZome = @"gmtTimeZome";

@implementation NSDate (display)

static NSDateFormatter *dateDisplayFormatter;

- (NSString *) formattedDisplayDate {
    
    if (dateDisplayFormatter == nil) {
        dateDisplayFormatter = [[NSDateFormatter alloc] init];
        dateDisplayFormatter.dateFormat = @"yyyy-MM-dd HH:mm zzz";
    }
    [self setTimeZoneForDateFormatter:dateDisplayFormatter];
    
    return [dateDisplayFormatter stringFromDate:self];
}

- (NSString *) formattedDisplayDateWithDateStyle: (NSDateFormatterStyle) dateStyle andTimeStyle: (NSDateFormatterStyle) timeStyle {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = dateStyle;
    dateFormatter.timeStyle = timeStyle;
    [self setTimeZoneForDateFormatter:dateFormatter];
    return [dateFormatter stringFromDate:self];
}

- (void) setTimeZoneForDateFormatter: (NSDateFormatter *) dateFormatter {
    BOOL gmtTimeZone = [NSDate isDisplayGMT];
    if (!gmtTimeZone) {
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    } else {
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
}

+ (BOOL) isDisplayGMT {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:kgmtTimeZome];
}

+ (void) setDisplayGMT: (BOOL) gmt {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:gmt forKey:kgmtTimeZome];
    [defaults synchronize];
}

@end
