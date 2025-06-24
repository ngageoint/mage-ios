//
//  AppDefaultContainerScheme.m
//  MAGE
//
//  Created by Brent Michalski on 6/24/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AppDefaultContainerScheme.h"
#import "AppDefaultColorScheme.h"
#import "AppDefaultShapeScheme.h"
#import "AppDefaultTypographyScheme.h"

@implementation AppDefaultContainerScheme

- (id<AppColorScheming>)colorScheme {
    return [[AppDefaultColorScheme alloc] init];
}

- (id<AppShapeScheming>)shapeScheme {
    return [[AppDefaultShapeScheme alloc] init];
}

- (id<AppTypographyScheming>)typographyScheme {
    return [[AppDefaultTypographyScheme alloc] init];
}

@end
