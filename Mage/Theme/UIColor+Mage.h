//
//  UIColor+Theme.h
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface UIColor (Mage)

+ (UIColor *) mageBlue;
+ (UIColor *) primaryText;
+ (UIColor *) secondaryText;
+ (UIColor *) background;
+ (UIColor *) tableBackground;
+ (UIColor *) dialog;
+ (UIColor *) brand;
+ (UIColor *) primary;
+ (UIColor *) secondary;
+ (UIColor *) themedButton;
+ (UIColor *) themedWhite;
+ (UIColor *) flatButton;
+ (UIColor *) brightButton;
+ (UIColor *) inactiveIcon;
+ (UIColor *) inactiveIconWithColor: (UIColor *) color;
+ (UIColor *) activeIcon;
+ (UIColor *) activeIconWithColor: (UIColor *) color;
+ (UIColor *) activeTabIcon;
+ (UIColor *) inactiveTabIcon;
+ (UIColor *) tabBarTint;
+ (UIColor *) navBarPrimaryText;
+ (UIColor *) navBarSecondaryText;
+ (void) themeMap: (MKMapView *) map;

@end
