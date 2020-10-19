//
//  MageTheme.m
//  MAGE
//
//  Created by Dan Barela on 3/1/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

@import HexColors;

#import "DayTheme.h"
#import "UIColor+Mage.h"

@implementation DayTheme

+ (instancetype) sharedInstance {
    static DayTheme *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSString *) displayName {
    return @"Day";
}

- (UIColor *) primaryText {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.87];
}

- (UIColor *) secondaryText {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.54];
}

- (UIColor *) background {
    return [UIColor whiteColor];
}

- (UIColor *) tableBackground {
    return [UIColor colorWithRed:.92 green:.92 blue:.95 alpha:1.0];
}

- (UIColor *) tableSeparator {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.2];
}

- (UIColor *) tableCellDisclosure {
    return [UIColor colorWithWhite:0 alpha:.23];
}

- (UIColor *) dialog {
    return [UIColor whiteColor];
}

- (UIColor *) primary {
    return [UIColor mageBlue];
}

- (UIColor *) secondary {
    return [UIColor whiteColor];
}

- (UIColor *) brand {
    return [UIColor mageBlue];
}

- (UIColor *) themedButton {
    return [UIColor mageBlue];
}

- (UIColor *) flatButton {
    return [UIColor mageBlue];
}

- (UIColor *) themedWhite {
    return [UIColor colorWithWhite:.75 alpha:1.0];
}

- (UIColor *) brightButton {
    return [[UIColor whiteColor] colorWithAlphaComponent:.87];
}

- (UIColor *) inactiveIcon {
    return [UIColor colorWithWhite:0.0 alpha:.38];
}

- (UIColor *) inactiveIconWithColor: (UIColor *) color {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b
                               alpha:.38];
    return nil;
}

- (UIColor *) activeIcon {
    return [UIColor colorWithWhite:0.0 alpha:.56];
}

- (UIColor *) activeIconWithColor: (UIColor *) color {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b
                               alpha:.54];
    return nil;
}

- (UIColor *) activeTabIcon {
    return [UIColor mageBlue];
}

- (UIColor *) inactiveTabIcon {
    return [self inactiveIcon];
}

- (UIColor *) tabBarTint {
    return [UIColor whiteColor];
}

- (UIColor *) navBarPrimaryText {
    return [UIColor whiteColor];
}

- (UIColor *) navBarSecondaryText {
    return [[UIColor whiteColor] colorWithAlphaComponent:87];
}

- (BOOL) darkMap {
    return NO;
}

- (UIKeyboardAppearance) keyboardAppearance {
    return UIKeyboardAppearanceLight;
}

@end
