//
//  NSDate+display.h
//  MAGE
//
//

#import <Foundation/Foundation.h>

@interface NSDate (display)
- (NSString *) formattedDisplayDate;
- (NSString *) formattedDisplayDateWithDateStyle: (NSDateFormatterStyle) dateStyle andTimeStyle: (NSDateFormatterStyle) timeStyle;
+ (BOOL) isDisplayGMT;
+ (void) setDisplayGMT: (BOOL) gmt;
@end
