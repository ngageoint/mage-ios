//
//  NSDate+display.m
//  MAGE
//
//

#import "NSDate+display.h"

NSString * const kgmtTimeZome = @"gmtTimeZome";

@implementation NSDate (display)

static NSDateFormatter *dateDisplayFormatter;
static NSDateFormatter *gmtDateDisplayFormatter;

- (NSString *) formattedDisplayDate {
    
    if (dateDisplayFormatter == nil) {
        dateDisplayFormatter = [[NSDateFormatter alloc] init];
        [dateDisplayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateDisplayFormatter setDateFormat:@"yyyy-MM-dd h:mm:ss a zzz"];
    }
    BOOL gmtTimeZone = [NSDate isDisplayGMT];
    if (!gmtTimeZone) {
        [dateDisplayFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    } else {
        [dateDisplayFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    return [dateDisplayFormatter stringFromDate:self];
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
