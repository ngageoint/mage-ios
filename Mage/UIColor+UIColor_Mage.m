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

+ (UIColor *) primaryColor {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"primaryColor"]];
}

+ (UIColor *) secondaryColor {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"secondaryColor"]];
}

+ (void) setPrimaryColor: (UIColor *) primaryColor {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:primaryColor] forKey:@"primaryColor"];
}

+ (void) setSecondaryColor: (UIColor *) secondaryColor {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:secondaryColor] forKey:@"secondaryColor"];
}

+ (UIColor *) darkerPrimary {
    return [UIColor darkerColorForColor:[UIColor primaryColor]];
}

+ (UIColor *) lighterPrimary {
    return [UIColor lighterColorForColor:[UIColor primaryColor]];
}

@end
