//
//  MageTheme.h
//  MAGE
//
//  Created by Dan Barela on 3/1/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DayTheme : NSObject

+ (UIColor *) primaryText;
+ (UIColor *) secondaryText;
+ (UIColor *) background;
+ (UIColor *) primary;
+ (UIColor *) secondary;
+ (UIColor *) brand;
+ (UIColor *) themedButton;
+ (UIColor *) flatButton;
+ (UIColor *) inactiveIcon;
+ (UIColor *) inactiveIconWithColor: (UIColor *) color;
+ (UIColor *) activeIcon;
+ (UIColor *) activeIconWithColor: (UIColor *) color;

@end
