//
//  LightColorScheme.h
//  MAGE
//
//  Created by Brent Michalski on 6/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppColorScheming.h"

@interface LightColorScheme : NSObject <AppColorScheming>
@property (nonatomic, strong) UIColor *primaryColor;
@property (nonatomic, strong) UIColor *primaryColorVariant;
@property (nonatomic, strong) UIColor *secondaryColor;
@property (nonatomic, strong) UIColor *onSecondaryColor;
@property (nonatomic, strong) UIColor *surfaceColor;
@property (nonatomic, strong) UIColor *onSurfaceColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *onBackgroundColor;
@property (nonatomic, strong) UIColor *errorColor;
@property (nonatomic, strong) UIColor *onPrimaryColor;
@end
