//
//  AppColorScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/11/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppColorScheming <NSObject>

@property (nonatomic, strong, readonly, nullable) UIColor *primaryColor;
@property (nonatomic, strong, readonly, nullable) UIColor *primaryColorVariant;
@property (nonatomic, strong, readonly, nullable) UIColor *secondaryColor;
@property (nonatomic, strong, readonly, nullable) UIColor *onSecondaryColor;
@property (nonatomic, strong, readonly, nullable) UIColor *surfaceColor;
@property (nonatomic, strong, readonly, nullable) UIColor *onSurfaceColor;
@property (nonatomic, strong, readonly, nullable) UIColor *backgroundColor;
@property (nonatomic, strong, readonly, nullable) UIColor *onBackgroundColor;
@property (nonatomic, strong, readonly, nullable) UIColor *errorColor;
@property (nonatomic, strong, readonly, nullable) UIColor *onPrimaryColor;

@end
