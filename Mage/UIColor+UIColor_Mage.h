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
+ (UIColor *) primaryColor;
+ (UIColor *) secondaryColor;
+ (void) setPrimaryColor: (UIColor *) primaryColor;
+ (void) setSecondaryColor: (UIColor *) secondaryColor;
+ (UIColor *) darkerPrimary;
+ (UIColor *) lighterPrimary;

@end
