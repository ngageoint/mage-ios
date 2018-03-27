//
//  UIColor+Theme.m
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIColor+Mage.h"
#import "ThemeManager.h"
#import "DayTheme.h"
#import "DarkTheme.h"

@interface MKMapView ()
-(void) _setShowsNightMode:(BOOL)yesOrNo;
@end

@implementation UIColor (Mage)

+ (UIColor *) mageBlue {
    return [UIColor colorWithRed:17.0/255.0 green:84.0/255.0 blue:164.0/255.0 alpha:1.0];
}

+ (void) themeMap: (MKMapView *) map {
    [map _setShowsNightMode:[[[ThemeManager sharedManager] curentThemeDefinition] darkMap]];
}

+ (UIColor *) primaryText {
    return [[[ThemeManager sharedManager] curentThemeDefinition] primaryText];
}

+ (UIColor *) secondaryText {
    return [[[ThemeManager sharedManager] curentThemeDefinition] secondaryText];
}

+ (UIColor *) brand {
    return [[[ThemeManager sharedManager] curentThemeDefinition] brand];
}

+ (UIColor *) background {
    return [[[ThemeManager sharedManager] curentThemeDefinition] background];
}

+ (UIColor *) tableBackground {
    return [[[ThemeManager sharedManager] curentThemeDefinition] tableBackground];
}

+ (UIColor *) dialog {
    return [[[ThemeManager sharedManager] curentThemeDefinition] dialog];
}

+ (UIColor *) primary {
    return [[[ThemeManager sharedManager] curentThemeDefinition] primary];
}

+ (UIColor *) secondary {
    return [[[ThemeManager sharedManager] curentThemeDefinition] secondary];
}

+ (UIColor *) themedButton {
    return [[[ThemeManager sharedManager] curentThemeDefinition] themedButton];
}

+ (UIColor *) flatButton {
    return [[[ThemeManager sharedManager] curentThemeDefinition] flatButton];
}

+ (UIColor *) inactiveIcon {
    return [[[ThemeManager sharedManager] curentThemeDefinition] inactiveIcon];
}

+ (UIColor *) inactiveIconWithColor:(UIColor *)color {
    return [[[ThemeManager sharedManager] curentThemeDefinition] inactiveIconWithColor: color];
}

+ (UIColor *) activeIcon {
    return [[[ThemeManager sharedManager] curentThemeDefinition] activeIcon];
}

+ (UIColor *) activeIconWithColor:(UIColor *)color {
    return [[[ThemeManager sharedManager] curentThemeDefinition] activeIconWithColor: color];
}

+ (UIColor *) activeTabIcon {
    return [[[ThemeManager sharedManager] curentThemeDefinition] activeTabIcon];
}

+ (UIColor *) inactiveTabIcon {
    return [[[ThemeManager sharedManager] curentThemeDefinition] inactiveTabIcon];
}

+ (UIColor *) tabBarTint {
    return [[[ThemeManager sharedManager] curentThemeDefinition] tabBarTint];
}

+ (UIColor *) navBarPrimaryText {
    return [[[ThemeManager sharedManager] curentThemeDefinition] navBarPrimaryText];
}

+ (UIColor *) navBarSecondaryText {
    return [[[ThemeManager sharedManager] curentThemeDefinition] navBarSecondaryText];
}

@end
