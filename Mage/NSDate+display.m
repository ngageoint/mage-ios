//
//  NSDate+display.m
//  MAGE
//
//

#import "NSDate+display.h"

NSString * const kLocalTimeZome = @"localTimeZome";

@implementation NSDate (display)

static NSDateFormatter *dateDisplayFormatter;
static NSDateFormatter *gmtDateDisplayFormatter;

- (NSString *) formattedDisplayDate {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    BOOL localTimeZone = [[defaults objectForKey:kLocalTimeZome] boolValue];
    
    if (dateDisplayFormatter == nil) {
        dateDisplayFormatter = [[NSDateFormatter alloc] init];
        [dateDisplayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateDisplayFormatter setDateFormat:@"yyyy-MM-dd h:mm:ss a zzz"];
    }
    
    if (localTimeZone) {
        [dateDisplayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    } else {
        [dateDisplayFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    return [dateDisplayFormatter stringFromDate:self];
}


@end
