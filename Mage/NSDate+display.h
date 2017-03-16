//
//  NSDate+display.h
//  MAGE
//
//

#import <Foundation/Foundation.h>

@interface NSDate (display)
- (NSString *) formattedDisplayDate;
+ (BOOL) isDisplayGMT;
+ (void) setDisplayGMT: (BOOL) gmt;
@end
