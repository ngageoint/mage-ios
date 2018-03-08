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

@implementation UIColor (Mage)

+ (UIColor *) primaryText {
    if (TheCurrentTheme == Night) {
        return [DarkTheme primaryText];
    }
    return [DayTheme primaryText];
}

+ (UIColor *) secondaryText {
    if (TheCurrentTheme == Night) {
        return [DarkTheme secondaryText];
    }
    return [DayTheme secondaryText];
}

+ (UIColor *) brand {
    if (TheCurrentTheme == Night) {
        return [DarkTheme brand];
    }
    return [DayTheme brand];
}

+ (UIColor *) background {
    if (TheCurrentTheme == Night) {
        return [DarkTheme background];
    }
    return [DayTheme background];
}

+ (UIColor *) primary {
    if (TheCurrentTheme == Night) {
        return [DarkTheme primary];
    }
    return [DayTheme primary];
}

+ (UIColor *) secondary {
    if (TheCurrentTheme == Night) {
        return [DarkTheme secondary];
    }
    return [DayTheme secondary];
}

+ (UIColor *) themedButton {
    if (TheCurrentTheme == Night) {
        return [DarkTheme themedButton];
    }
    return [DayTheme themedButton];
}

+ (UIColor *) flatButton {
    if (TheCurrentTheme == Night) {
        return [DarkTheme flatButton];
    }
    return [DayTheme flatButton];
}

+ (UIColor *) inactiveIcon {
    if (TheCurrentTheme == Night) {
        return [DarkTheme inactiveIcon];
    }
    return [DayTheme inactiveIcon];
}

+ (UIColor *) inactiveIconWithColor:(UIColor *)color {
    if (TheCurrentTheme == Night) {
        return [DarkTheme inactiveIconWithColor: color];
    }
    return [DayTheme inactiveIconWithColor: color];
}

+ (UIColor *) activeIcon {
    if (TheCurrentTheme == Night) {
        return [DarkTheme activeIcon];
    }
    return [DayTheme activeIcon];
}

+ (UIColor *) activeIconWithColor:(UIColor *)color {
    if (TheCurrentTheme == Night) {
        return [DarkTheme activeIconWithColor: color];
    }
    return [DayTheme activeIconWithColor: color];
}

@end
