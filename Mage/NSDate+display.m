//
//  NSDate+display.m
//  MAGE
//
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
