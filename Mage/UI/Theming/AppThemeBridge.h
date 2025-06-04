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
+ (id<AppContainerScheming>)defaultTheme;
+ (id<AppContainerScheming>)darkTheme;
- (void)applyTheme:(id<AppContainerScheming>)scheme;
@end
