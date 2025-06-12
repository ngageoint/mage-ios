//
//  AppContainerScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppColorScheming.h"
#import "AppShapeScheming.h"
#import "AppTypographyScheming.h"

@protocol AppColorScheming;
@protocol AppShapeScheming;
@protocol AppTypographyScheming;

@protocol AppContainerScheming
@property (nonatomic, readonly) id<AppColorScheming> colorScheme;
@property (nonatomic, readonly) id<AppShapeScheming> shapeScheme;
@property (nonatomic, readonly) id<AppTypographyScheming> typographyScheme;
@end
