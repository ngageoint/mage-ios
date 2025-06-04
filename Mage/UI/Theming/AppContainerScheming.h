//
//  AppContainerScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AppColorScheming.h"
#import "AppShapeScheming.h"
#import "AppTypographyScheming.h"

@protocol AppContainerScheming <NSObject>
@property (nonatomic, strong, readonly) id<AppColorScheming> colorScheme;
@property (nonatomic, strong, readonly) id<AppShapeScheming> shapeScheme;
@property (nonatomic, strong, readonly) id<AppTypographyScheming> typographyScheme;
@end
