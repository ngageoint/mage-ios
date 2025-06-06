//
//  AppThemeBridge.h
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppContainerScheming.h"

@interface AppThemeBridge : NSObject

// Matches MAGEScheme.scheme() for backward compatibility
+ (id<AppContainerScheming>)scheme;

// Matches MAGEScheme.setupApplicationAppearance for backward compatibility
+ (void)setupApplicationAppearance:(id<AppContainerScheming>)scheme;

+ (id<AppContainerScheming>)defaultTheme;
+ (id<AppContainerScheming>)errorTheme;
+ (id<AppContainerScheming>)disabledTheme;

+ (void)applyTheme:(id<AppContainerScheming>)scheme;

@end
