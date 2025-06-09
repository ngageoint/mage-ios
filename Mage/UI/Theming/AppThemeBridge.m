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

+ (void)applySecondaryThemeToButton:(UIButton *)button scheme:(id<AppContainerScheming>)scheme {
    [AppThemeManager applySecondaryThemeToButton:button with:scheme];
}

+ (void)applyPrimaryThemeToButton:(UIButton *)button scheme:(id<AppContainerScheming>)scheme {
    [AppThemeManager applyPrimaryThemeToButton:button with:scheme];
}

+ (void)applyDisabledThemeToButton:(UIButton *)button scheme:(id<AppContainerScheming>)scheme {
    [AppThemeManager applyDisabledThemeToButton:button with:scheme];
}

+ (void)applyPrimaryThemeToTextField:(UITextField *)textField scheme:(id<AppContainerScheming>)scheme {
  [AppThemeManager applyPrimaryThemeToTextField:textField with:scheme];
}

+ (void)applyDisabledThemeToTextField:(UITextField *)textField scheme:(id<AppContainerScheming>)scheme {
    [AppThemeManager applyDisabledThemeToTextField:textField with:scheme];
}

@end
