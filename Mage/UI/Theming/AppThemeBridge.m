//
//  AppThemeBridge.m
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AppThemeBridge.h"
#import "Mage-Swift.h"

@implementation AppThemeBridge

// Backward compatibility for MAGEScheme.scheme()
+ (id<AppContainerScheming>)scheme {
    return [self defaultTheme];
}

// Backward compatibility for MAGEScheme.setupApplicationAppearance
+ (void)setupApplicationAppearance:(id<AppContainerScheming>)scheme {
    [self applyTheme:scheme];
}

+ (id<AppContainerScheming>)defaultTheme {
    return [[NamedColorTheme alloc] init];
}

+ (id<AppContainerScheming>)errorTheme {
    return [[ErrorColorTheme alloc] init];
}

+ (id<AppContainerScheming>)disabledTheme {
    return [[DisabledColorTheme alloc] init];
}

+ (void)applyTheme:(id<AppContainerScheming>)scheme {
    [AppThemeManager applyAppearanceWith: scheme];
}

@end
