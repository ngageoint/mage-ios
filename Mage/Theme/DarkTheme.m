//
//  DarkTheme.m
//  MAGE
//
//  Created by Dan Barela on 3/1/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

@import HexColors;

#import "DarkTheme.h"
#import "UIColor+UIColor_Mage.h"

@implementation DarkTheme

+ (UIColor *) primaryText {
    return [UIColor whiteColor];
}

+ (UIColor *) secondaryText {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:.7];
}

+ (UIColor *) background {
    return [UIColor colorWithHexString:@"303030"];
}

+ (UIColor *) tableBackground {
    return [DarkTheme background];
}

+ (UIColor *) dialog {
    return [UIColor colorWithHexString:@"424242"];
}

+ (UIColor *) primary {
    return [UIColor colorWithHexString:@"455A64"];
}

+ (UIColor *) secondary {
    return [UIColor colorWithHexString:@"263238"];
}

+ (UIColor *) brand {
    return [DarkTheme primaryText];
}

+ (UIColor *) themedButton {
    return [UIColor mageBlue];
}

+ (UIColor *) flatButton {
    return [DarkTheme primaryText];
}

+ (UIColor *) inactiveIcon {
    return [UIColor colorWithWhite:1.0 alpha:.50];
}

+ (UIColor *) inactiveIconWithColor: (UIColor *) color {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b
                               alpha:.5];
    return nil;
}

+ (UIColor *) activeIcon {
    return [UIColor colorWithWhite:1.0 alpha:1.0];
}

+ (UIColor *) activeIconWithColor: (UIColor *) color {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b
                               alpha:1.0];
    return nil;
}

+ (UIColor *) activeTabIcon {
    return [DarkTheme activeIcon];
}

+ (UIColor *) inactiveTabIcon {
    return [DarkTheme inactiveIcon];
}

+ (UIColor *) tabBarTint {
    return [DarkTheme primary];
}

+ (UIColor *) navBarPrimaryText {
    return [UIColor whiteColor];
}

+ (UIColor *) navBarSecondaryText {
    return [[UIColor whiteColor] colorWithAlphaComponent:.87];
}

+ (BOOL) darkMap {
    return YES;
}

@end
