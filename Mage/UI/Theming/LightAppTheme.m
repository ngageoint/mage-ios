//
//  LightAppTheme.m
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LightAppTheme.h"
#import "LightColorScheme.h"

@interface LightShapeScheme : NSObject <AppShapeScheming>
@end

@implementation LightShapeScheme
- (CGFloat)cornerRadius { return 8.0; }
- (CGFloat)borderWidth { return 1.0; }
@end

@interface LightTypographyScheme : NSObject <AppTypographyScheming>
@end

@implementation LightTypographyScheme
- (UIFont *)headlineFont { return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; }
- (UIFont *)bodyFont { return [UIFont preferredFontForTextStyle:UIFontTextStyleBody]; }
- (UIFont *)buttonFont { return [UIFont preferredFontForTextStyle:UIFontTextStyleCallout]; }
@end

@implementation LightAppTheme {
    LightColorScheme *_colorScheme;
    LightShapeScheme *_shapeScheme;
    LightTypographyScheme *_typographyScheme;
}

- (instancetype)init {
    if (self = [super init]) {
        _colorScheme = [[LightColorScheme alloc] init];
        _shapeScheme = [[LightShapeScheme alloc] init];
        _typographyScheme = [[LightTypographyScheme alloc] init];
    }
    return self;
}

- (id<AppColorScheming>)colorScheme { return _colorScheme; }
- (id<AppShapeScheming>)shapeScheme { return _shapeScheme; }
- (id<AppTypographyScheming>)typographyScheme { return _typographyScheme; }
@end
