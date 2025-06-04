//
//  AppColorScheming.h
//  MAGE
//
//  Created by Brent Michalski on 6/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppColorScheming <NSObject>
@property (nonatomic, strong, readonly) UIColor *primaryColor;
@property (nonatomic, strong, readonly) UIColor *primaryColorVariant;
@property (nonatomic, strong, readonly) UIColor *secondaryColor;
@property (nonatomic, strong, readonly) UIColor *onSecondaryColor;
@property (nonatomic, strong, readonly) UIColor *surfaceColor;
@property (nonatomic, strong, readonly) UIColor *onSurfaceColor;
@property (nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nonatomic, strong, readonly) UIColor *onBackgroundColor;
@property (nonatomic, strong, readonly) UIColor *errorColor;
@property (nonatomic, strong, readonly) UIColor *onPrimaryColor;
@end
