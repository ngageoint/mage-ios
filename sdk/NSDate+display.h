//
//  NSDate+display.h
//  mage-ios-sdk
//
//  Created by William Newman on 3/12/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (display)
- (NSString *) formattedDisplayDate;
- (NSString *) formattedDisplayDateWithDateStyle: (NSDateFormatterStyle) dateStyle andTimeStyle: (NSDateFormatterStyle) timeStyle;
+ (BOOL) isDisplayGMT;
+ (void) setDisplayGMT: (BOOL) gmt;
@end

NS_ASSUME_NONNULL_END
