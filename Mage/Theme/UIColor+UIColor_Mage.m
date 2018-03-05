//
//  UIColor+UIColor_Mage.m
//  MAGE
//
//  Created by Dan Barela on 8/16/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIColor+UIColor_Mage.h"

@implementation UIColor (UIColor_Mage)

+ (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat h, s, b, a;
    if ([c getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.3, 1.0)
                               alpha:a];
    return nil;
}

+ (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat h, s, b, a;
    if ([c getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}

+ (UIColor *) mageBlue {
    return [UIColor colorWithRed:17.0/255.0 green:84.0/255.0 blue:164.0/255.0 alpha:1.0];
}

+ (UIColor *) mageBlue54 {
    return [UIColor colorWithRed:17.0/255.0 green:84.0/255.0 blue:164.0/255.0 alpha:.54];
}

+ (UIColor *) primaryColor {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"primaryColor"]];
}

+ (UIColor *) secondaryColor {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"secondaryColor"]];
}

+ (void) setPrimaryColor: (UIColor *) primaryColor {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:primaryColor] forKey:@"primaryColor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) setSecondaryColor: (UIColor *) secondaryColor {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:secondaryColor] forKey:@"secondaryColor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UIColor *) darkerPrimary {
    return [UIColor darkerColorForColor:[UIColor primaryColor]];
}

+ (UIColor *) lighterPrimary {
    return [UIColor lighterColorForColor:[UIColor primaryColor]];
}

+ (UIColor *) accentColor {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"accentColor"]];
}

+ (void) setAccentColor: (UIColor *) accentColor {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:accentColor] forKey:@"accentColor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UIColor *) backgroundColor {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"backgroundColor"]];
}

+ (void) setBackgroundColor: (UIColor *) backgroundColor {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:backgroundColor] forKey:@"backgroundColor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UIColor *) primaryDarkText {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.87];
}

+ (UIColor *) secondaryDarkText {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.54];
}

+ (UIColor *) primaryLightText {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
}

+ (UIColor *) secondaryLightText {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:.7];
}

@end
