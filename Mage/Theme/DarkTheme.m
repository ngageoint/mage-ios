//
//  DarkTheme.m
//  MAGE
//
//  Created by Dan Barela on 3/1/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

@import HexColors;

#import "DarkTheme.h"
#import "UIColor+Mage.h"
#import <MaterialComponents/MDCPalettes.h>

@implementation DarkTheme

+ (instancetype) sharedInstance {
    static DarkTheme *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSString *) displayName {
    return @"Night";
}

- (UIColor *) primaryText {
    return [UIColor whiteColor];
}

- (UIColor *) secondaryText {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:.7];
}

- (UIColor *) background {
    return [UIColor colorWithHexString:@"303030"];
}

- (UIColor *) tableBackground {
    return MDCPalette.greyPalette.tint900;
}

- (UIColor *) tableSeparator {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:.2];
}

- (UIColor *) tableCellDisclosure {
    return [UIColor colorWithWhite:1 alpha:.23];
}

- (UIColor *) dialog {
    return MDCPalette.greyPalette.tint800;
}

- (UIColor *) primary {
    return MDCPalette.blueGreyPalette.tint700;
}

- (UIColor *) secondary {
    return MDCPalette.blueGreyPalette.tint900;
}

- (UIColor *) brand {
    return [self primaryText];
}

- (UIColor *) themedButton {
    return [UIColor mageBlue];
}

- (UIColor *) flatButton {
    return [self primaryText];
}

- (UIColor *) themedWhite {
    return [UIColor colorWithWhite:.9 alpha:1.0];
}

- (UIColor *) brightButton {
    return [[UIColor whiteColor] colorWithAlphaComponent:.87];
}

- (UIColor *) inactiveIcon {
    return [UIColor colorWithWhite:1.0 alpha:.50];
}

- (UIColor *) inactiveIconWithColor: (UIColor *) color {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b
                               alpha:.5];
    return nil;
}

- (UIColor *) activeIcon {
    return [UIColor colorWithWhite:1.0 alpha:.8];
}

- (UIColor *) activeIconWithColor: (UIColor *) color {
    CGFloat h, s, b, a;
    if ([color getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b
                               alpha:1.0];
    return nil;
}

- (UIColor *) activeTabIcon {
    return [self activeIcon];
}

- (UIColor *) inactiveTabIcon {
    return [self inactiveIcon];
}

- (UIColor *) tabBarTint {
    return [self primary];
}

- (UIColor *) navBarPrimaryText {
    return [UIColor whiteColor];
}

- (UIColor *) navBarSecondaryText {
    return [[UIColor whiteColor] colorWithAlphaComponent:.87];
}

- (BOOL) darkMap {
    return YES;
}

- (UIKeyboardAppearance) keyboardAppearance {
    return UIKeyboardAppearanceDark;
}

@end
