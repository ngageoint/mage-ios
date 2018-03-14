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
//+ (void) setupAppearance {
//    [UIColor setPrimaryColor:[UIColor colorWithHexString:@"455A64"]];
//    [UIColor setSecondaryColor:[UIColor colorWithHexString:@"263238"]];
//
//    [UIColor setBackgroundColor:[UIColor colorWithHexString:@"303030"]];
//
//    [[BackgroundView appearance] setBackgroundColor:[UIColor backgroundColor]];
//
//    [[UINavigationBar appearance] setBarTintColor:[UIColor secondaryColor]];
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{
//                                                           NSForegroundColorAttributeName: [UIColor whiteColor]
//                                                           }];
//    [[UINavigationBar appearance] setTranslucent:NO];
//    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTintColor:[UIColor whiteColor]];
//
//    [[UITableView appearance] setBackgroundColor:[UIColor backgroundColor]];
//    [[UITableViewCell appearance] setBackgroundColor:[UIColor backgroundColor]];
//    [[UILabel appearance] setTextColor:[UIColor primaryLightText]];
//    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]] setTextColor:[UIColor primaryLightText]];
//
//    [[SecondaryLabel appearance] setTextColor:[UIColor secondaryLightText]];
//
//    [[UITableViewHeaderFooterView appearance] setBackgroundColor:[UIColor backgroundColor]];
//    [[UITableViewHeaderFooterView appearance] setTintColor:[UIColor primaryLightText]];
//
////    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableView class]]] setTextColor:[UIColor secondaryLightText] ];
////    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableView class]]] setBackgroundColor:[UIColor backgroundColor]];
//
//    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[TableSectionHeader class]]] setTextColor:[UIColor secondaryLightText] ];
//    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[TableSectionHeader class]]] setBackgroundColor:[UIColor backgroundColor]];
//    [[TableSectionHeader appearance] setBackgroundColor:[UIColor redColor]];
//    [[TableSectionHeader appearance] setTintColor:[UIColor greenColor]];
//    SectionHeaderLabel *headerLabel = [SectionHeaderLabel appearance];
//    headerLabel.backgroundColor = [UIColor backgroundColor];
//    headerLabel.textColor = [UIColor secondaryLightText];
//    headerLabel.tintColor = [UIColor secondaryLightText];
//    headerLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
//    [headerLabel setFont:[UIFont systemFontOfSize:14]];
//
//
//    ThemedButton *themeButtonAppearance = [ThemedButton appearance];
//    themeButtonAppearance.backgroundColor = [UIColor mageBlue54];
//    [themeButtonAppearance setTitleColor:[UIColor primaryLightText] forState:UIControlStateNormal];
//
//    UIButton *buttonAppearance = [UIButton appearance];
//    [buttonAppearance setTitleColor:[UIColor primaryLightText] forState:UIControlStateNormal];
//
//    BrandLabel *brandLabelAppearance = [BrandLabel appearance];
//    [brandLabelAppearance setTextColor:[UIColor primaryLightText]];
//
//    [[UITextView appearance] setTextColor:[UIColor primaryLightText]];
//
//    [[UIActivityIndicatorView appearance] setColor:[UIColor primaryLightText]];
//
//    // these are inverted from the rest of the app
//    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
//    [[UITabBar appearance] setBarTintColor:[UIColor secondaryColor]];
//
//    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTextColor:[UIColor whiteColor]];
//    if (@available(iOS 11.0, *)) {
//        [[UISearchBar appearance] setBarTintColor:[UIColor primaryColor]];
//        [[UISearchBar appearance] setTintColor:[UIColor secondaryColor]];
//        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[UIColor secondaryColor]}];
//        [[UINavigationBar appearance] setPrefersLargeTitles:NO];
//        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{
//                                                                    NSForegroundColorAttributeName: [UIColor whiteColor]
//                                                                    }];
//    } else {
//        // Fallback on earlier versions
//    }
//}

@end
