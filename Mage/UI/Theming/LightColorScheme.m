//
//  LightColorScheme.m
//  MAGE
//
//  Created by Brent Michalski on 6/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LightColorScheme.h"

@implementation LightColorScheme
- (UIColor *)primaryColor { return [UIColor systemBlueColor]; }
- (UIColor *)primaryColorVariant { return [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; }
- (UIColor *)secondaryColor { return [UIColor systemOrangeColor]; }
- (UIColor *)onSecondaryColor { return [UIColor labelColor]; }
- (UIColor *)surfaceColor { return [UIColor whiteColor]; }
- (UIColor *)onSurfaceColor { return [UIColor blackColor]; }
- (UIColor *)backgroundColor { return [UIColor systemGroupedBackgroundColor]; }
- (UIColor *)onBackgroundColor { return [UIColor labelColor]; }
- (UIColor *)errorColor { return [UIColor systemRedColor]; }
- (UIColor *)onPrimaryColor { return [UIColor whiteColor]; }
@end
