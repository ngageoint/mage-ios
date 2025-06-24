//
//  AppDefaultColorScheme.m
//  MAGE
//
//  Created by Brent Michalski on 6/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AppDefaultColorScheme.h"
#import <UIKit/UIKit.h>

@implementation AppDefaultColorScheme

- (UIColor *)primaryColor {
    return UIColor.systemBlueColor;
}

- (UIColor *)primaryColorVariant {
    return UIColor.systemBlueColor;
}

- (UIColor *)secondaryColor {
    return UIColor.systemOrangeColor;
}

- (UIColor *)onSecondaryColor {
    return UIColor.labelColor;
}

- (UIColor *)surfaceColor {
    return UIColor.systemBackgroundColor;
}

- (UIColor *)onSurfaceColor {
    return UIColor.labelColor;
}

- (UIColor *)backgroundColor {
    return UIColor.systemBackgroundColor;
}

- (UIColor *)onBackgroundColor {
    return UIColor.labelColor;
}

- (UIColor *)errorColor {
    return UIColor.systemRedColor;
}

- (UIColor *)onPrimaryColor {
    return UIColor.whiteColor;
}

// Add more properties as needed from AppColorScheming

@end
