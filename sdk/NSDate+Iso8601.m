//
//  NSDate+Iso8601.m
//  mage-ios-sdk
//
//

#import "NSDate+Iso8601.h"

@implementation NSDate (Iso8601)

- (NSString *) iso8601String {
    return [[NSDate getDateFormatter] stringFromDate:self];
}

+ (NSDate *) dateFromIso8601String: (NSString *) iso8601String {
    return [[NSDate getDateFormatter] dateFromString:iso8601String];
}

+ (NSDateFormatter *) getDateFormatter {
    static NSDateFormatter* dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
    });
    
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSLog(@"The current device locale %@",[NSLocale currentLocale].localeIdentifier);
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:locale];
    NSLog(@"The date formatter locale %@", dateFormatter.locale.localeIdentifier);
    
    return dateFormatter;
}


@end
