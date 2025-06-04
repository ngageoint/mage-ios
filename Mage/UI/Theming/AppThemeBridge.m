//
//  AppThemeBridge.m
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AppThemeBridge.h"
#import "LightAppTheme.h"
#import "DarkAppTheme.h"
#import "MAGE-Swift.h"

@implementation AppThemeBridge

+ (id<AppContainerScheming>)defaultTheme {
    return [[LightAppTheme alloc] init];
}

+ (id<AppContainerScheming>)darkTheme {
    return [[DarkAppTheme alloc] init];
}

- (void)applyTheme:(id<AppContainerScheming>)scheme {
    [AppThemeManager applyAppearanceWith:scheme];
}

@end
