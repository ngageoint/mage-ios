//
//  DarkAppTheme.m
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DarkAppTheme.h"

@interface DarkColorScheme : NSObject <AppColorScheming>
@end

@implementation DarkColorScheme
- (UIColor *)primaryColor { return [UIColor systemBlueColor]; }
- (UIColor *)primaryColorVariant { return [UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:1.0]; }
- (UIColor *)secondaryColor { return [UIColor systemOrangeColor]; }
- (UIColor *)onSecondaryColor { return [UIColor whiteColor]; }
- (UIColor *)surfaceColor { return [UIColor systemGray6Color]; }
- (UIColor *)onSurfaceColor { return [UIColor whiteColor]; }
- (UIColor *)backgroundColor { return [UIColor blackColor]; }
- (UIColor *)onBackgroundColor { return [UIColor whiteColor]; }
- (UIColor *)errorColor { return [UIColor systemRedColor]; }
- (UIColor *)onPrimaryColor { return [UIColor whiteColor]; }
@end

@interface DarkShapeScheme : NSObject <AppShapeScheming>
@end

@implementation DarkShapeScheme
- (CGFloat)cornerRadius { return 8.0; }
- (CGFloat)borderWidth { return 1.0; }
@end

@interface DarkTypographyScheme : NSObject <AppTypographyScheming>
@end

@implementation DarkTypographyScheme
- (UIFont *)headlineFont { return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; }
- (UIFont *)bodyFont { return [UIFont preferredFontForTextStyle:UIFontTextStyleBody]; }
- (UIFont *)buttonFont { return [UIFont preferredFontForTextStyle:UIFontTextStyleCallout]; }
@end

@implementation DarkAppTheme {
    DarkColorScheme *_colorScheme;
    DarkShapeScheme *_shapeScheme;
    DarkTypographyScheme *_typographyScheme;
}

- (instancetype)init {
    if (self = [super init]) {
        _colorScheme = [[DarkColorScheme alloc] init];
        _shapeScheme = [[DarkShapeScheme alloc] init];
        _typographyScheme = [[DarkTypographyScheme alloc] init];
    }
    return self;
}

- (id<AppColorScheming>)colorScheme { return _colorScheme; }
- (id<AppShapeScheming>)shapeScheme { return _shapeScheme; }
- (id<AppTypographyScheming>)typographyScheme { return _typographyScheme; }
@end
