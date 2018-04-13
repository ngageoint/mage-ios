//
//  UIColor+UIColor_Mage.h
//  MAGE
//
//  Created by Dan Barela on 8/16/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (UIColor_Mage)

+ (UIColor *) mageBlue;
+ (UIColor *) mageBlue54;
+ (UIColor *) primaryColor;
+ (UIColor *) secondaryColor;
+ (UIColor *) accentColor;
+ (UIColor *) backgroundColor;
+ (void) setPrimaryColor: (UIColor *) primaryColor;
+ (void) setSecondaryColor: (UIColor *) secondaryColor;
+ (void) setAccentColor: (UIColor *) accentColor;
+ (void) setBackgroundColor: (UIColor *) backgroundColor;
+ (UIColor *) darkerPrimary;
+ (UIColor *) lighterPrimary;
+ (UIColor *) primaryDarkText;
+ (UIColor *) secondaryDarkText;
+ (UIColor *) primaryLightText;
+ (UIColor *) secondaryLightText;

@end
