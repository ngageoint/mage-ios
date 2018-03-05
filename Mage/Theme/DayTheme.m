//
//  MageTheme.m
//  MAGE
//
//  Created by Dan Barela on 3/1/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DayTheme.h"
#import "UIColor+UIColor_Mage.h"

@implementation DayTheme

+ (UIColor *) primaryText {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.87];
}

+ (UIColor *) secondaryText {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:.54];
}

+ (UIColor *) background {
    return [UIColor whiteColor];
}

+ (UIColor *) primary {
    return [UIColor mageBlue];
}

+ (UIColor *) secondary {
    return [UIColor whiteColor];
}

+ (UIColor *) brand {
    return [UIColor mageBlue];
}

+ (UIColor *) themedButton {
    return [UIColor mageBlue];
}

+ (UIColor *) flatButton {
    return [UIColor mageBlue];
}

//+ (void) setupAppearance {
//    [UIColor setPrimaryColor:[UIColor mageBlue]];
//    [UIColor setSecondaryColor:[UIColor whiteColor]];
//
//    [[UINavigationBar appearance] setBarTintColor:[UIColor primaryColor]];
//    [[UINavigationBar appearance] setTintColor:[UIColor secondaryColor]];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{
//                                                           NSForegroundColorAttributeName: [UIColor secondaryColor]
//                                                           }];
//    [[UINavigationBar appearance] setTranslucent:NO];
//    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTintColor:[UIColor secondaryColor]];
//
//    // these are inverted from the rest of the app
//    [[UITabBar appearance] setTintColor:[UIColor primaryColor]];
//    [[UITabBar appearance] setBarTintColor:[UIColor secondaryColor]];
//
//    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTextColor:[UIColor secondaryColor]];
//    if (@available(iOS 11.0, *)) {
//        [[UISearchBar appearance] setBarTintColor:[UIColor primaryColor]];
//        [[UISearchBar appearance] setTintColor:[UIColor secondaryColor]];
//        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[UIColor secondaryColor]}];
//        [[UINavigationBar appearance] setPrefersLargeTitles:NO];
//        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{
//                                                                    NSForegroundColorAttributeName: [UIColor secondaryColor]
//                                                                    }];
//    } else {
//        // Fallback on earlier versions
//    }
//}

@end