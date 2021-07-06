//
//  NSString+Contains.m
//  mage-ios-sdk
//
//

#import "NSString+Contains.h"

@implementation NSString (Contains)

- (BOOL)safeContainsString:(NSString*)other {
    NSRange range = [self rangeOfString:other];
    return range.length != 0;
}

@end
