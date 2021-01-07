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
#import <MaterialComponents/MDCPalettes.h>

@implementation UIColor (Mage)

+ (UIColor *) mageBlue {
    return MDCPalette.bluePalette.tint600;
}

+ (void) themeMap: (MKMapView *) map {
    // Commenting out; see above before this is uncommented or removed
//    if ([map respondsToSelector:@selector(_setShowsNightMode:)]) {
//        [map _setShowsNightMode:[[[ThemeManager sharedManager] curentThemeDefinition] darkMap]];
//    }
}

+ (BOOL) darkMap{
    return [[[ThemeManager sharedManager] curentThemeDefinition] darkMap];
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

+ (UIColor *) tableSeparator {
    return [[[ThemeManager sharedManager] curentThemeDefinition] tableSeparator];
}

+ (UIColor *) tableCellDisclosure {
    return [[[ThemeManager sharedManager] curentThemeDefinition] tableCellDisclosure];
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

+ (UIColor *) themedWhite {
    return [[[ThemeManager sharedManager] curentThemeDefinition] themedWhite];
}

+ (UIColor *) brightButton {
    return [[[ThemeManager sharedManager] curentThemeDefinition] brightButton];
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

+ (UIKeyboardAppearance) keyboardAppearance {
    return [[[ThemeManager sharedManager] curentThemeDefinition] keyboardAppearance];
}

@end
