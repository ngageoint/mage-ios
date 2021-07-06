//
//  NSDate+Iso8601.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface NSDate (Iso8601)

- (NSString *) iso8601String;

+ (NSDate *) dateFromIso8601String: (NSString *) iso8601String;

@end
